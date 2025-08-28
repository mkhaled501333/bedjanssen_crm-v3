import { TicketItemsReportRequest, TicketItemsReportResponse } from './types';
import { authFetch, getApiBaseUrl } from '../../../../../shared/utils';

export class TicketItemsReportAPI {
  private static getApiBaseURL() {
    return getApiBaseUrl();
  }

  static async getTicketItemsReport(
    request: TicketItemsReportRequest
  ): Promise<TicketItemsReportResponse> {
    try {
      const response = await authFetch(`${this.getApiBaseURL()}/api/reports/ticket-items`, {
        method: 'POST',
        body: JSON.stringify(request),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(
          errorData.error || `HTTP error! status: ${response.status}`
        );
      }

      const result = await response.json();
      
      // Check if the response has a success field (following project pattern)
      if (result.success === false) {
        throw new Error(result.error || result.message || 'API request failed');
      }

      return result;
    } catch (error) {
      console.error('Ticket items report API error:', error);
      throw error;
    }
  }

  static async getInitialReport(companyId: number): Promise<TicketItemsReportResponse> {
    const request: TicketItemsReportRequest = {
      filters: { companyId },
      page: 1,
      limit: 50,
    };

    return this.getTicketItemsReport(request);
  }

  static async getFilteredReport(
    filters: TicketItemsReportRequest['filters'],
    page: number = 1,
    limit: number = 50
  ): Promise<TicketItemsReportResponse> {
    const request: TicketItemsReportRequest = {
      filters,
      page,
      limit,
    };

    return this.getTicketItemsReport(request);
  }
}

export default TicketItemsReportAPI;
