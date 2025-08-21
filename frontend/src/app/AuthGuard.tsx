"use client";
import { useEffect, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';

export default function AuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [checked, setChecked] = useState(false);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const token = window.localStorage.getItem('token');
      if (!token && pathname !== '/auth/login') {
        router.replace('/auth/login');
      } else {
        setChecked(true);
      }
    }
  }, [pathname, router]);

  if (!checked && pathname !== '/auth/login') return null;
  return <>{children}</>;
} 