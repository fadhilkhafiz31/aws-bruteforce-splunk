USE securebank_db;

UPDATE users
SET  password_hash = '$2a$10$l82t9oMQp4zsIJ5UQcLgLebJ6zuS1wwKfMZBp.lvr163xD6MXsHHy', updated_at = now()
WHERE id=2;
