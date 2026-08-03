from rest_framework import serializers
from django.contrib.auth import get_user_model

Usuario = get_user_model()

class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)