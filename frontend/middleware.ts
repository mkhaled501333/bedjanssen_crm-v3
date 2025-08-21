import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('token')?.value;
  const isLoginPage = request.nextUrl.pathname.startsWith('/auth/login');

  if (!token && !isLoginPage) {
    return NextResponse.redirect(new URL('/auth/login', request.url));
  }
  return NextResponse.next();
}

export const config = {
  matcher: [
    // Protect all routes except static, API, and login
    '/((?!_next|api|auth/login|public).*)',
  ],
}; 