import { NextResponse } from 'next/server';
import { API_URL } from '../../../../../src/lib/config';

export async function POST(request: Request) {
  try {
    const { token, password, password2 } = await request.json();

    if (!token || !password || !password2) {
      return NextResponse.json(
        { message: 'All fields are required' },
        { status: 400 }
      );
    }

    if (password !== password2) {
      return NextResponse.json(
        { message: 'Passwords do not match' },
        { status: 400 }
      );
    }

    const response = await fetch(`${API_URL}/auth/reset-password/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        token,
        password,
        password2,
      }),
    });

    if (!response.ok) {
      const data = await response.json();
      return NextResponse.json(
        { message: data.detail || 'Failed to reset password' },
        { status: response.status }
      );
    }

    return NextResponse.json(
      { message: 'Password reset successfully' },
      { status: 200 }
    );
  } catch (error) {
    console.error('Password reset error:', error);
    return NextResponse.json(
      { message: 'Internal server error' },
      { status: 500 }
    );
  }
} 