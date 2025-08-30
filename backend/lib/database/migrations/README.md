# Database Migrations

This folder contains the database migration files organized by functionality instead of one large file.

## File Structure

### `index.dart`
Main export file that makes all migration functions available to the main `migrations.dart` file.

### `base_migrations.dart`
Contains:
- Helper functions for safe table and index creation
- Basic table creation logic for all database tables
- Error handling for DDL operations

### `tickets_report_indexes.dart`
Contains all indexes related to tickets reporting:
- Core tickets table indexes
- Customer table indexes
- Ticket categories indexes
- Ticket items indexes
- Ticket call indexes
- Product and request reason indexes
- User indexes
- Performance monitoring indexes

### `ticket_items_report_indexes.dart`
Contains additional indexes specifically for ticket items reporting:
- Ticket item change table indexes
- Maintenance table indexes
- Advanced reporting indexes
- Geographic and product filtering indexes

### `views.dart`
Contains database view creation:
- `ticket_items_report` view for comprehensive reporting

### `seed_data.dart`
Contains initial data insertion:
- Entities data (users, customers, tickets, etc.)
- Activities data (user actions, customer operations, etc.)

### `utilities.dart`
Contains utility functions:
- Index usage analysis
- Performance monitoring functions

## Usage

The main `migrations.dart` file orchestrates all migrations by calling the functions from these individual files. This approach provides:

1. **Better organization**: Each file has a specific responsibility
2. **Easier maintenance**: Changes to specific functionality are isolated
3. **Better readability**: Smaller files are easier to understand
4. **Modularity**: Individual migration components can be tested independently

## Adding New Migrations

To add new migrations:

1. Create a new file in this folder for the specific functionality
2. Add the export to `index.dart`
3. Call the new migration function from the main `runMigrations` function in `migrations.dart`

## Migration Order

The migrations run in this order:
1. Basic tables creation
2. Tickets report indexes
3. Ticket items report indexes
4. Database views
5. Seed data insertion

This order ensures that tables exist before creating indexes and views.
