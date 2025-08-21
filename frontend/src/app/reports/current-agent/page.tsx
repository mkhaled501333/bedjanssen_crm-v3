'use client';

import React from 'react';
import { CurrentAgentReport } from '@/features/reports/reports/current-agent';

export default function CurrentAgentReportPage() {
  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        <CurrentAgentReport />
      </div>
    </div>
  );
} 