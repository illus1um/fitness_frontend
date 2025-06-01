from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, EmailStr
from typing import Dict
import random
import string
from datetime import datetime, timedelta

router = APIRouter()

# Хранилище кодов верификации (в реальном приложении использовать Redis или БД)
verification_codes: Dict[str, Dict] = {}

class EmailSchema(BaseModel):
    email: EmailStr

class VerificationSchema(BaseModel):
    email: EmailStr
    code: str

def generate_verification_code(length: int = 6) -> str:
    """Генерирует код верификации указанной длины"""
    return ''.join(random.choices(string.digits, k=length))

@router.post("/verify/send")
async def send_verification_code(email_data: EmailSchema):
    """Отправляет код верификации на email"""
    email = email_data.email
    
    # Проверяем, не отправляли ли мы код недавно
    if email in verification_codes:
        last_sent = verification_codes[email]["timestamp"]
        if datetime.now() - last_sent < timedelta(minutes=1):
            raise HTTPException(
                status_code=429,
                detail="Please wait 1 minute before requesting a new code"
            )
    
    # Генерируем новый код
    code = generate_verification_code()
    
    # Сохраняем код и время отправки
    verification_codes[email] = {
        "code": code,
        "timestamp": datetime.now(),
        "attempts": 0
    }
    
    # TODO: Отправить email с кодом
    # В реальном приложении здесь будет код для отправки email
    # Для тестирования выводим код в консоль
    print(f"Verification code for {email}: {code}")
    
    return {"message": "Verification code has been sent"}

@router.post("/verify/check")
async def verify_code(verification_data: VerificationSchema):
    """Проверяет код верификации"""
    email = verification_data.email
    code = verification_data.code
    
    if email not in verification_codes:
        raise HTTPException(
            status_code=400,
            detail="No verification code was sent to this email"
        )
    
    verification_info = verification_codes[email]
    
    # Проверяем, не истек ли код (15 минут)
    if datetime.now() - verification_info["timestamp"] > timedelta(minutes=15):
        del verification_codes[email]
        raise HTTPException(
            status_code=400,
            detail="Verification code has expired"
        )
    
    # Проверяем количество попыток
    if verification_info["attempts"] >= 3:
        raise HTTPException(
            status_code=429,
            detail="Too many attempts. Please request a new code"
        )
    
    # Увеличиваем счетчик попыток
    verification_info["attempts"] += 1
    
    # Проверяем код
    if verification_info["code"] != code:
        raise HTTPException(
            status_code=400,
            detail="Invalid verification code"
        )
    
    # Код верный, удаляем его из хранилища
    del verification_codes[email]
    
    return {"message": "Email verified successfully"} 