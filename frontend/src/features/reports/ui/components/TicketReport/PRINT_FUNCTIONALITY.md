# Print Functionality for Ticket Items Report

## Overview

The Ticket Items Report now includes a comprehensive print functionality that allows users to print selected tickets in a formatted complaint report format, similar to the image provided.

## Features

### Print Button Locations
1. **Table Header Row**: A dedicated row below the main table headers with a print button
2. **Toolbar**: A print button in the main toolbar for easy access

### Print Button States
- **Enabled**: When tickets are selected (green button)
- **Disabled**: When no tickets are selected (gray button)

## How to Use

### 1. Select Tickets
- Use the checkboxes in the first column to select individual tickets
- Use the "Select All" checkbox in the header to select all visible tickets
- Selected rows will be highlighted in blue

### 2. Print Selected Tickets
- Click the print button in either location:
  - **Table Header**: 🖨️ طباعة التذاكر المحددة
  - **Toolbar**: 🖨️ Print Selected

### 3. Print Output
- A new window will open with the formatted complaint reports
- Each ticket will be displayed as a separate complaint form
- Click the "🖨️ طباعة" button in the print window to print

## Print Format

The printed output follows the exact format shown in the reference image:

### Header Section
- Ticket Serial Number
- Company Name: "شركة بيد يانسن للمراتب والمفروشات Bedjanssen co"
- Form Title: "نموذج ابلاغ عن حالة وجود شكاوى العملاء"

### Customer Information
- Date (current date)
- Customer Name
- Governorate
- City
- Address
- Customer Phone Numbers

### Product Table
- Product Name
- Size/Dimensions
- Quantity
- Purchase Date
- Place of Purchase
- Reason for Complaint

### Footer Sections
- Quality Department Delivery Date (blank for filling)
- Notes (blank for filling)
- Technical Report (blank for filling)
- Complaint Receiver (filled with ticket creator name)

## Technical Implementation

### API Integration
- Uses the `/api/reports/ticket-items/by-ids` endpoint
- Fetches detailed ticket information including customer data and items
- Converts ticket item IDs to ticket IDs for API calls

### Print Service
- **Location**: `services/printService.ts`
- **Main Method**: `PrintService.printSelectedTickets(ticketIds: number[])`
- **Features**:
  - Fetches ticket data from API
  - Generates HTML with Arabic RTL support
  - Opens print window with formatted content
  - Handles errors gracefully

### Styling
- **CSS Classes**: 
  - `.printHeaderRow` - Styling for the print button row
  - `.printButton` - Styling for the print button
  - `.printToolbarButton` - Styling for toolbar print button
- **Responsive Design**: Adapts to different screen sizes
- **Print Media**: Optimized CSS for print output

## Error Handling

- **No Selection**: Shows alert "يرجى تحديد التذاكر للطباعة"
- **API Errors**: Shows alert "حدث خطأ أثناء الطباعة. يرجى المحاولة مرة أخرى."
- **Network Issues**: Graceful fallback with user-friendly error messages

## Browser Compatibility

- Modern browsers with ES6+ support
- Print functionality works in all major browsers
- RTL (Right-to-Left) text support for Arabic content

## Future Enhancements

- Print preview functionality
- Customizable print templates
- Batch printing options
- Export to PDF
- Print history tracking
