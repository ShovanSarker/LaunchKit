"""
Views for the accounts app.
"""

from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from django.contrib.auth import get_user_model
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes
from django.conf import settings

from apps.accounts.serializers import (
    UserSerializer, 
    CustomTokenObtainPairSerializer,
    ChangePasswordSerializer,
    ResetPasswordEmailSerializer,
    ResetPasswordSerializer,
    UserProfileSerializer,
)

User = get_user_model()

class RegisterView(generics.CreateAPIView):
    """
    API endpoint for user registration.
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.AllowAny]


class CustomTokenObtainPairView(TokenObtainPairView):
    """
    Custom token obtain pair view that uses our custom serializer.
    """
    serializer_class = CustomTokenObtainPairSerializer


class ChangePasswordView(generics.UpdateAPIView):
    """
    API endpoint for changing password.
    """
    serializer_class = ChangePasswordSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        return self.request.user
    
    def update(self, request, *args, **kwargs):
        user = self.get_object()
        serializer = self.get_serializer(data=request.data)
        
        if serializer.is_valid():
            # Check old password
            if not user.check_password(serializer.data.get("old_password")):
                return Response({"old_password": ["Wrong password."]}, status=status.HTTP_400_BAD_REQUEST)
            
            # Set new password
            user.set_password(serializer.data.get("new_password"))
            user.save()
            
            return Response({"detail": "Password updated successfully."}, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ResetPasswordEmailView(APIView):
    """
    API endpoint for requesting a password reset email.
    """
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        serializer = ResetPasswordEmailSerializer(data=request.data)
        
        if serializer.is_valid():
            email = serializer.validated_data["email"]
            
            try:
                user = User.objects.get(email=email)
                
                # Generate token
                token = default_token_generator.make_token(user)
                uid = urlsafe_base64_encode(force_bytes(user.pk))
                
                # Construct reset URL - in a real app, we'd send an email here
                reset_url = f"{settings.FRONTEND_URL}/auth/reset-password?uid={uid}&token={token}"
                
                # For demo purposes, just return the URL
                return Response({"detail": "Password reset email sent.", "reset_url": reset_url}, status=status.HTTP_200_OK)
            
            except User.DoesNotExist:
                # Don't reveal whether a user account exists
                pass
                
        return Response({"detail": "Password reset email sent if the account exists."}, status=status.HTTP_200_OK)


class ResetPasswordView(APIView):
    """
    API endpoint for resetting password with token.
    """
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        serializer = ResetPasswordSerializer(data=request.data)
        
        if serializer.is_valid():
            uid = serializer.validated_data["uid"]
            token = serializer.validated_data["token"]
            password = serializer.validated_data["password"]
            
            try:
                user_id = urlsafe_base64_decode(uid).decode()
                user = User.objects.get(pk=user_id)
                
                if default_token_generator.check_token(user, token):
                    user.set_password(password)
                    user.save()
                    return Response({"detail": "Password reset successful."}, status=status.HTTP_200_OK)
                else:
                    return Response({"detail": "Invalid token."}, status=status.HTTP_400_BAD_REQUEST)
                
            except (TypeError, ValueError, OverflowError, User.DoesNotExist):
                return Response({"detail": "Invalid user."}, status=status.HTTP_400_BAD_REQUEST)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UserProfileView(generics.RetrieveAPIView):
    """
    API endpoint for retrieving user profile.
    """
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        return self.request.user


class ProfileUpdateView(generics.UpdateAPIView):
    """
    API endpoint for updating user profile.
    """
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        return self.request.user 