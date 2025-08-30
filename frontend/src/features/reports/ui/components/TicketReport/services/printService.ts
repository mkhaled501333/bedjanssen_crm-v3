import { getApiBaseUrl, authFetch } from '../../../../../../shared/utils';

interface PrintTicketData {
  id: number;
  customerName: string;
  governorateName: string;
  cityName: string;
  adress: string;
  phones: string[];
  createdByName: string;
  items: {
    productName: string;
    productSize: string;
    quantity: number;
    purchaseDate: string;
    purchaseLocation: string;
    requestReasonName: string;
    requestReasonDetail: string;
  }[];
}

export class PrintService {
  // PrintService class for handling ticket printing in both Janssen and Englander formats
  private static async fetchTicketData(ticketIds: number[]): Promise<PrintTicketData[]> {
    try {
      const apiUrl = `${getApiBaseUrl()}/api/reports/ticket-items/by-ids`;
      console.log('Fetching from API:', apiUrl);
      console.log('Request payload:', { ticketIds });
      
      const response = await authFetch(apiUrl, {
        method: 'POST',
        body: JSON.stringify({ ticketIds }),
      });

      console.log('Response status:', response.status);
      console.log('Response headers:', Object.fromEntries(response.headers.entries()));

      if (!response.ok) {
        let errorMessage = `HTTP error! status: ${response.status}`;
        try {
          const errorData = await response.json();
          if (errorData.error) {
            errorMessage = errorData.error;
          }
        } catch {
          console.log('Could not parse error response');
        }
        throw new Error(errorMessage);
      }

      const data = await response.json();
      console.log('Response data:', data);
      
      if (!data.success) {
        throw new Error(data.error || 'Failed to fetch ticket data');
      }

      return data.tickets;
    } catch (error) {
      console.error('Error fetching ticket data for printing:', error);
      throw error;
    }
  }

  private static generatePrintHTML(tickets: PrintTicketData[]): string {
    const currentDate = new Date().toLocaleDateString('ar-EG');
    
    let html = `
      <!DOCTYPE html>
      <html dir="rtl" lang="ar">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>تقرير التذاكر المحددة</title>
        <style>
          @media print {
            body { margin: 0; }
            .no-print { display: none; }
          }
          body {
            font-family: 'Arial', sans-serif;
            margin: 30px;
            direction: rtl;
            text-align: right;
            min-height: 100vh;
          }
          .ticket {
            page-break-inside: avoid;
            margin-bottom: 20px;
            border: 2px solid #333;
            padding: 5px;
            border-radius: 8px;
            min-height: auto;
          }
          .ticket-header {
            text-align: center;
            margin-bottom: 15px;
            border-bottom: 2px solid #333;
            padding-bottom: 10px;
          }
          .ticket-serial {
            font-size: 16px;
            font-weight: bold;
            margin-bottom: 8px;
          }
          .company-name {
            font-size: 14px;
            margin-bottom: 5px;
          }
          .form-title {
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 10px;
          }
          .customer-info {
            display: flex;
            flex-direction: column;
            gap: 0;
            margin-bottom: 25;
          }
          .info-item {
            display: flex;
            align-items: center;
            gap: 0;
            min-height: 0;
            margin: 0;
            padding: 4px 0;
          }
          .info-label {
            font-weight: bold;
            min-width: 120px;
          }
          .info-value {
            font-weight: normal;
            margin-left: 5px;
          }
          .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
            min-height: auto;
          }
          .items-table th,
          .items-table td {
            border: 1px solid #333;
            padding: 12px;
            text-align: center;
            min-height: 40px;
          }
          .items-table th {
            background-color: #f0f0f0;
            font-weight: bold;
          }
          .footer-sections {
            margin-top: 30px;
          }
          .footer-item {
            margin-bottom: 35px;
          }
          .footer-label {
            font-weight: bold;
            margin-bottom: 12px;
          }
          .footer-content {
            min-height: 80px;
          }
          
          .delivery-date .footer-content {
            min-height: 60px;
          }
          
          .notes .footer-content {
            min-height: 100px;
          }
          
          .technical-report .footer-content {
            min-height: 120px;
          }
          
          .complaint-receiver .footer-content {
            min-height: 40px;
          }
          .print-button {
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 10px 20px;
            background-color: #007bff;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
          }
          .print-button:hover {
            background-color: #0056b3;
          }
        </style>
      </head>
      <body>
        <button class="print-button no-print" onclick="window.print()">🖨️ طباعة</button>
    `;

    tickets.forEach((ticket) => {
      html += `
        <div class="ticket">
          <div class="ticket-header">
            <div class="ticket-serial">رقم التذكرة: ${ticket.id}</div>
            <div class="company-name">شركة بيد يانسن للمراتب والمفروشات Bedjanssen co</div>
            <div class="form-title">نموذج ابلاغ عن حالة وجود شكاوى العملاء</div>
          </div>
          
          <div class="customer-info">
            <div class="info-item">
              <span class="info-label">التاريخ: <span class="info-value">${currentDate}</span></span>
            </div>
            <div class="info-item">
              <span class="info-label">اسم العميل: <span class="info-value">${ticket.customerName || 'غير محدد'}</span></span>
            </div>
            <div class="info-item">
              <span class="info-label">المحافظة: <span class="info-value">${ticket.governorateName || 'غير محدد'}</span></span>
            </div>
            <div class="info-item">
              <span class="info-label">المدينة: <span class="info-value">${ticket.cityName || 'غير محدد'}</span></span>
            </div>
            <div class="info-item">
              <span class="info-label">العنوان: <span class="info-value">${ticket.adress || 'غير محدد'}</span></span>
            </div>
            <div class="info-item">
              <span class="info-label">تيليفون العميل: <span class="info-value">${ticket.phones.join(', ') || 'غير محدد'}</span></span>
            </div>
          </div>
          
          <table class="items-table">
            <thead>
              <tr>
                <th>اسم المنتج</th>
                <th>المقاس</th>
                <th>الكمية</th>
                <th>تاريخ الشراء</th>
                <th>مكان الشراء</th>
                <th>سبب الشكوى</th>
              </tr>
            </thead>
            <tbody>
      `;

      if (ticket.items && ticket.items.length > 0) {
        ticket.items.forEach(item => {
          html += `
            <tr>
              <td>${item.productName || ''}</td>
              <td>${item.productSize || ''}</td>
              <td>${item.quantity || ''}</td>
              <td>${item.purchaseDate || ''}</td>
              <td>${item.purchaseLocation || ''}</td>
              <td>${item.requestReasonName || ''}</td>
            </tr>
          `;
        });
      } else {
        html += `
          <tr>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
          </tr>
        `;
      }

      html += `
            </tbody>
          </table>
          
          <div class="footer-sections">
            <div class="footer-item delivery-date">
              <div class="footer-label">تم تسليم هذا النموذج القسم الجودة بتاريخ:</div>
              <div class="footer-content"></div>
            </div>
            <div class="footer-item notes">
              <div class="footer-label">ملاحظات:</div>
              <div class="footer-content"></div>
            </div>
            <div class="footer-item technical-report">
              <div class="footer-label">تقرير الفني:</div>
              <div class="footer-content"></div>
            </div>
            <div class="footer-item complaint-receiver">
              <div class="footer-label">متلقى الشكوى: ${ticket.createdByName || 'غير محدد'}</div>
            </div>
          </div>
        </div>
      `;
    });

    html += `
      </body>
      </html>
    `;

    return html;
  }

  private static generateEnglanderPrintHTML(tickets: PrintTicketData[]): string {
    const currentDate = new Date().toLocaleDateString('ar-EG');
    
    let html = `
      <!DOCTYPE html>
      <html dir="rtl" lang="ar">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>تقرير التذاكر المحددة - نموذج انجلندر</title>
        <style>
          @media print {
            body { margin: 0; }
            .no-print { display: none; }
          }
          body {
            font-family: 'Arial', sans-serif;
            margin: 30px;
            direction: rtl;
            text-align: right;
            min-height: 100vh;
          }
          .ticket {
            page-break-inside: avoid;
            margin-bottom: 20px;
            border: 2px solid #333;
            padding: 5px;
            border-radius: 8px;
            min-height: auto;
          }
          .ticket-header {
            text-align: center;
            margin-bottom: 15px;
            border-bottom: 2px solid #333;
            padding-bottom: 10px;
          }
          .ticket-serial {
            font-size: 16px;
            font-weight: bold;
            margin-bottom: 8px;
          }
          .company-name {
            font-size: 14px;
            margin-bottom: 5px;
          }
          .company-name-arabic {
            font-size: 14px;
            margin-bottom: 5px;
            color: #333;
          }
          .form-title {
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 10px;
          }
          .customer-info {
            display: flex;
            flex-direction: column;
            gap: 0;
            margin-bottom: 25px;
          }
          .info-item {
            display: flex;
            align-items: center;
            gap: 0;
            min-height: 0;
            margin: 0;
            padding: 4px 0;
          }
          .info-label {
            font-weight: bold;
            min-width: 120px;
          }
          .info-value {
            font-weight: normal;
            margin-left: 5px;
          }
          .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
            min-height: auto;
          }
          .items-table th,
          .items-table td {
            border: 1px solid #333;
            padding: 12px;
            text-align: center;
            min-height: 40px;
          }
          .items-table th {
            background-color: #f0f0f0;
            font-weight: bold;
          }
          .footer-sections {
            margin-top: 30px;
          }
          .footer-item {
            margin-bottom: 35px;
          }
          .footer-label {
            font-weight: bold;
            margin-bottom: 12px;
          }
          .footer-content {
            min-height: 80px;
          }
          
          .notes .footer-content {
            min-height: 100px;
          }
          
          .complaint-receiver .footer-content {
            min-height: 40px;
          }
          
          .print-button {
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 10px 20px;
            background-color: #007bff;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
          }
          .print-button:hover {
            background-color: #0056b3;
          }
        </style>
      </head>
      <body>
        <button class="print-button no-print" onclick="window.print()">🖨️ طباعة</button>
    `;

    tickets.forEach((ticket) => {
      html += `
        <div class="ticket">
          <div class="ticket-header">
            <div class="ticket-serial">رقم التذكرة: ${ticket.id}</div>
            <div class="company-name">m.m.m Bed HanssenCo</div>
            <div class="company-name-arabic">شركة مصطفى محمد بيد يانسن</div>
            <div class="form-title">نموذج ابلاغ عن حالة وجود شكاوى العملاء</div>
          </div>
          
          <div class="customer-info">
            <div class="info-item">
              <span class="info-label">التاريخ: <span class="info-value">${currentDate}</span></span>
            </div>
            <div class="info-item">
              <span class="info-label">اسم العميل: <span class="info-value">${ticket.customerName || 'غير محدد'}</span></span>
            </div>
            <div class="info-item">
              <span class="info-label">المحافظة: <span class="info-value">${ticket.governorateName || 'غير محدد'}</span></span>
            </div>
            <div class="info-item">
              <span class="info-label">المدينة: <span class="info-value">${ticket.cityName || 'غير محدد'}</span></span>
            </div>
            <div class="info-item">
              <span class="info-label">العنوان: <span class="info-value">${ticket.adress || 'غير محدد'}</span></span>
            </div>
            <div class="info-item">
              <span class="info-label">تيليفون العميل: <span class="info-value">${ticket.phones.join(', ') || 'غير محدد'}</span></span>
            </div>
          </div>
          
          <table class="items-table">
            <thead>
              <tr>
                <th>اسم المنتج</th>
                <th>المقاس</th>
                <th>الكمية</th>
                <th>تاريخ الشراء</th>
                <th>مكان الشراء</th>
                <th>سبب الشكوى</th>
              </tr>
            </thead>
            <tbody>
      `;

      if (ticket.items && ticket.items.length > 0) {
        ticket.items.forEach(item => {
          html += `
            <tr>
              <td>${item.productName || ''}</td>
              <td>${item.productSize || ''}</td>
              <td>${item.quantity || ''}</td>
              <td>${item.purchaseDate || ''}</td>
              <td>${item.purchaseLocation || ''}</td>
              <td>${item.requestReasonName || ''}</td>
            </tr>
          `;
        });
      } else {
        html += `
          <tr>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
          </tr>
        `;
      }

      html += `
            </tbody>
          </table>
          
          <div class="footer-sections">
            <div class="footer-item notes">
              <div class="footer-label">ملاحظات:</div>
              <div class="footer-content"></div>
            </div>
            <div class="footer-item complaint-receiver">
              <div class="footer-label">متلقى الشكوى: ${ticket.createdByName || 'غير محدد'}</div>
            </div>
          </div>
        </div>
      `;
    });

    html += `
      </body>
      </html>
    `;

    return html;
  }



  public static async printSelectedTickets(ticketIds: number[]): Promise<void> {
    if (ticketIds.length === 0) {
      alert('يرجى تحديد التذاكر للطباعة');
      return;
    }

    try {
      console.log('Starting print process for ticket IDs:', ticketIds);
      console.log('API Base URL:', getApiBaseUrl());
      
      const tickets = await this.fetchTicketData(ticketIds);
      console.log('Successfully fetched tickets:', tickets);
      
      const printHTML = this.generatePrintHTML(tickets);
      console.log('Generated print HTML');
      
      const printWindow = window.open('', '_blank');
      if (printWindow) {
        printWindow.document.write(printHTML);
        printWindow.document.close();
        printWindow.focus();
        console.log('Print window opened successfully');
      } else {
        throw new Error('Failed to open print window');
      }
    } catch (error) {
      console.error('Error printing tickets:', error);
      
      // More specific error messages
      if (error instanceof Error) {
        if (error.message.includes('HTTP error! status: 500')) {
          alert('خطأ في الخادم. يرجى التحقق من اتصال قاعدة البيانات أو المحاولة مرة أخرى لاحقاً.');
          
          // Show a fallback message with the ticket IDs that were selected
          const fallbackMessage = `تم تحديد التذاكر التالية للطباعة:\n${ticketIds.join(', ')}\n\nالخطأ: مشكلة في الخادم. يرجى المحاولة مرة أخرى لاحقاً.`;
          alert(fallbackMessage);
        } else if (error.message.includes('HTTP error! status: 401')) {
          alert('خطأ في المصادقة. يرجى تسجيل الدخول مرة أخرى.');
        } else if (error.message.includes('HTTP error! status: 404')) {
          alert('نقطة النهاية غير موجودة. يرجى التحقق من إعدادات الخادم.');
        } else {
          alert(`حدث خطأ أثناء الطباعة: ${error.message}`);
        }
      } else {
        alert('حدث خطأ أثناء الطباعة. يرجى المحاولة مرة أخرى.');
      }
    }
  }

  public static async printEnglanderFormat(ticketIds: number[]): Promise<void> {
    if (ticketIds.length === 0) {
      alert('يرجى تحديد التذاكر للطباعة');
      return;
    }

    try {
      console.log('Starting Englander format print process for ticket IDs:', ticketIds);
      console.log('API Base URL:', getApiBaseUrl());
      
      const tickets = await this.fetchTicketData(ticketIds);
      console.log('Successfully fetched tickets for Englander format:', tickets);
      
      const printHTML = this.generateEnglanderPrintHTML(tickets);
      console.log('Generated Englander format print HTML');
      
      const printWindow = window.open('', '_blank');
      if (printWindow) {
        printWindow.document.write(printHTML);
        printWindow.document.close();
        printWindow.focus();
        console.log('Englander format print window opened successfully');
      } else {
        throw new Error('Failed to open print window');
      }
    } catch (error) {
      console.error('Error printing Englander format:', error);
      
      // More specific error messages
      if (error instanceof Error) {
        if (error.message.includes('HTTP error! status: 500')) {
          alert('خطأ في الخادم. يرجى التحقق من اتصال قاعدة البيانات أو المحاولة مرة أخرى لاحقاً.');
        } else if (error.message.includes('HTTP error! status: 401')) {
          alert('خطأ في المصادقة. يرجى تسجيل الدخول مرة أخرى.');
        } else if (error.message.includes('HTTP error! status: 404')) {
          alert('نقطة النهاية غير موجودة. يرجى التحقق من إعدادات الخادم.');
        } else {
          alert(`حدث خطأ أثناء الطباعة: ${error.message}`);
        }
      } else {
        alert('حدث خطأ أثناء الطباعة. يرجى المحاولة مرة أخرى.');
      }
    }
  }
}
