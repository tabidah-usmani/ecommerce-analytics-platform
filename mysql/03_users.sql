-- Read-only user for the extraction pipeline (least privilege).
-- Change the password so it matches MYSQL_EXTRACT_PASSWORD in your .env.
CREATE USER IF NOT EXISTS 'extractor'@'%' IDENTIFIED BY 'change_me';
GRANT SELECT ON olist_source.* TO 'extractor'@'%';
FLUSH PRIVILEGES;