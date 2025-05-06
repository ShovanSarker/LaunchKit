"""
URL configuration for the accounts app.
"""

from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from apps.accounts.views import (
    RegisterView,
    ChangePasswordView,
    ResetPasswordEmailView,
    ResetPasswordView,
    CustomTokenObtainPairView,
    UserProfileView,
    ProfileUpdateView,
)

urlpatterns = [
    # Authentication endpoints
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('change-password/', ChangePasswordView.as_view(), name='change_password'),
    path('reset-password-email/', ResetPasswordEmailView.as_view(), name='reset_password_email'),
    path('reset-password/', ResetPasswordView.as_view(), name='reset_password'),
    
    # Profile endpoints
    path('profile/', UserProfileView.as_view(), name='user_profile'),
    path('profile/update/', ProfileUpdateView.as_view(), name='profile_update'),
] 