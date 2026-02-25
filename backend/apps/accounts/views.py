from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.mail import send_mail
from django.conf import settings
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework_simplejwt.tokens import RefreshToken
import uuid

from .serializers import (
    RegisterSerializer, UserProfileSerializer, ChangePasswordSerializer,
    PasswordResetRequestSerializer, PasswordResetConfirmSerializer,
    CustomTokenObtainPairSerializer,
)

User = get_user_model()


class RegisterView(generics.CreateAPIView):
    """User registration endpoint."""
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = RegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Send verification email
        self._send_verification_email(user)

        return Response(
            {'message': 'Registration successful. Please verify your email.'},
            status=status.HTTP_201_CREATED
        )

    def _send_verification_email(self, user):
        verification_url = f"{settings.FRONTEND_URL}/verify-email/{user.email_verification_token}"
        send_mail(
            subject='Verify your Novel Reading account',
            message=f'Click to verify: {verification_url}',
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            fail_silently=True,
        )


class LoginView(TokenObtainPairView):
    """JWT Login endpoint."""
    permission_classes = (permissions.AllowAny,)
    serializer_class = CustomTokenObtainPairSerializer


class LogoutView(APIView):
    """Logout and blacklist refresh token."""
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({'message': 'Logged out successfully.'}, status=status.HTTP_200_OK)
        except Exception:
            return Response({'error': 'Invalid token.'}, status=status.HTTP_400_BAD_REQUEST)


class EmailVerificationView(APIView):
    """Email verification via token."""
    permission_classes = (permissions.AllowAny,)

    def get(self, request, token):
        try:
            user = User.objects.get(email_verification_token=token)
            user.email_verified = True
            user.email_verification_token = None
            user.save(update_fields=['email_verified', 'email_verification_token'])
            return Response({'message': 'Email verified successfully.'})
        except User.DoesNotExist:
            return Response({'error': 'Invalid or expired token.'}, status=status.HTTP_400_BAD_REQUEST)


class UserProfileView(generics.RetrieveUpdateAPIView):
    """Get and update authenticated user profile."""
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = UserProfileSerializer

    def get_object(self):
        return self.request.user


class ChangePasswordView(APIView):
    """Change user password."""
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user
        if not user.check_password(serializer.validated_data['old_password']):
            return Response({'error': 'Invalid current password.'}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(serializer.validated_data['new_password'])
        user.save(update_fields=['password'])
        return Response({'message': 'Password changed successfully.'})


class PasswordResetRequestView(APIView):
    """Send password reset email."""
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            user = User.objects.get(email=serializer.validated_data['email'])
            user.password_reset_token = uuid.uuid4()
            user.password_reset_expires = timezone.now() + timezone.timedelta(hours=24)
            user.save(update_fields=['password_reset_token', 'password_reset_expires'])

            reset_url = f"{settings.FRONTEND_URL}/reset-password/{user.password_reset_token}"
            send_mail(
                subject='Password Reset Request',
                message=f'Click to reset your password: {reset_url}\nThis link expires in 24 hours.',
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                fail_silently=True,
            )
        except User.DoesNotExist:
            pass  # Don't reveal if email exists

        return Response({'message': 'If the email exists, a reset link has been sent.'})


class PasswordResetConfirmView(APIView):
    """Confirm password reset with token."""
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            user = User.objects.get(password_reset_token=serializer.validated_data['token'])
            if user.password_reset_expires < timezone.now():
                return Response({'error': 'Reset token has expired.'}, status=status.HTTP_400_BAD_REQUEST)

            user.set_password(serializer.validated_data['new_password'])
            user.password_reset_token = None
            user.password_reset_expires = None
            user.save(update_fields=['password', 'password_reset_token', 'password_reset_expires'])
            return Response({'message': 'Password reset successfully.'})
        except User.DoesNotExist:
            return Response({'error': 'Invalid token.'}, status=status.HTTP_400_BAD_REQUEST)


class UserStatsView(APIView):
    """Get reading statistics for the authenticated user."""
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request):
        from apps.reading.models import ReadingProgress, Bookmark
        user = request.user

        stats = {
            'total_books_started': ReadingProgress.objects.filter(user=user).count(),
            'total_books_completed': ReadingProgress.objects.filter(user=user, is_completed=True).count(),
            'total_bookmarks': Bookmark.objects.filter(user=user).count(),
            'total_reading_time_minutes': ReadingProgress.objects.filter(
                user=user
            ).aggregate(
                total=__import__('django.db.models', fromlist=['Sum']).Sum('reading_time_minutes')
            )['total'] or 0,
        }
        return Response(stats)
