

-  `ticket_items.id`
-  `ticket_items.product_id`
-  `product_info.id` based on `ticket_items.product_id`
-  `product_info.product_name` based on `ticket_items.product_id`
-  `ticket_items.product_size`
-  `ticket_items.request_reason_id`
-  `request_reasons.name` based on `ticket_items.request_reason_id`
-  `ticket_items.inspected`
-  `ticket_items.inspection_date`
-  `ticket_items.client_approval`
-  `ticket_items.ticket_id`

if item has ticket_item_change_another return استبدال لنفس النوع  as actoin and
-  `ticket_item_change_another.pulled`
-  `ticket_item_change_another.delivered`

or it hase ticket_item_change_same return استبدال لنوع اخر  as actoin and
-  `ticket_item_change_same.pulled`
-  `ticket_item_change_same.delivered`


or it has ticket_item_maintenance return صيانه   as actoin and
-  `ticket_item_maintenance.pulled`
-  `ticket_item_maintenance.delivered`


-  `tickets.id` based on  `ticket_items.ticket_id`
-  `tickets.company_id` based on  `ticket_items.ticket_id`
-  `tickets.ticket_cat_id` based on  `ticket_items.ticket_id`
-  `ticket_categories.name`based on `tickets.ticket_cat_id`
-  `tickets.status` based on  `ticket_items.ticket_id`


-  `customers.id` based on  `tickets.customer_id`
-  `customers.name` based on  `tickets.customer_id`
-  `customers.governomate_id` based on  `tickets.customer_id`
-  `governorates.name` based on `customers.governomate_id`
-  `customers.city_id` based on  `tickets.customer_id`
-  `cities.name`  based on `tickets.customer_id`


reorder it like 
customer_id
customer_name
governomate_id
governorate_name
city_id
city_name
ticket_id
company_id
ticket_cat_id
ticket_category_name
ticket_status
ticket_item_id
product_id
product_info_id
product_name
product_size
request_reason_id
request_reason_name
inspected
inspection_date
client_approval
action
pulled_status
delivered_status


filters on 
customer_ids
governomate_ids
city_ids
ticket_ids
company_ids
ticket_cat_ids
ticket_status
product_ids
request_reason_ids
inspected
inspection_date from to 
action
pulled_status
delivered_status