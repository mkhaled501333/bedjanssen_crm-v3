SELECT DISTINCT
    g.id AS governorate_id,
    g.name AS governorate_name,
    COUNT(DISTINCT c.id) AS customer_count,
    COUNT(DISTINCT t.id) AS ticket_count
FROM governorates g
INNER JOIN customers c ON g.id = c.governomate_id
INNER JOIN tickets t ON c.id = t.customer_id
GROUP BY g.id, g.name
ORDER BY g.name;
