CREATE TABLE IF NOT EXISTS users (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username      VARCHAR(50)  NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  email         VARCHAR(100) NOT NULL UNIQUE,
  display_name  VARCHAR(100) NOT NULL,
  role          ENUM('admin', 'user') NOT NULL DEFAULT 'user',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS users (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username      VARCHAR(50)  NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  email         VARCHAR(100) NOT NULL UNIQUE,
  display_name  VARCHAR(100) NOT NULL,
  role          ENUM('admin', 'user') NOT NULL DEFAULT 'user',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS auth_codes (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code          VARCHAR(255) NOT NULL UNIQUE,
  user_id       INT UNSIGNED NOT NULL,
  client_id     VARCHAR(100) NOT NULL,
  redirect_uri  VARCHAR(500) NOT NULL,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS security_events (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  event_type    VARCHAR(50)  NOT NULL,
  endpoint      VARCHAR(100),
  src_ip        VARCHAR(45),
  username      VARCHAR(50),
  user_id       INT UNSIGNED,
  status_code   SMALLINT UNSIGNED,
  reason        VARCHAR(255),
  metadata      JSON,                  -- flexible field for extra context
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_event_type (event_type),
  INDEX idx_src_ip     (src_ip),
  INDEX idx_created_at (created_at)
);

USE securebank_db;
SELECT * FROM users ;

UPDATE securebank_db.users
SET password_hash= '$2a$10$Hugdl7SLr4llk0QT294PyOCdAM9XSjgVzYDNTTMC3zDIeGGxNAXdK' , updated_at = now()
WHERE id=2;

INSERT INTO users (username, password_hash, email, display_name, role)
VALUES
  (
    'admin',
    '$2a$10$VK55GLXff3UsZ3VniFOP6edTvRlPvha0QLq7vmP2hz8UqzBoim.la',
    'admin@securebank-demo.my',
    'Branch Administrator',
    'admin'
  ),
  (
    'user123',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    'user123@securebank-demo.my',
    'Bank Customer',
    'user'
  );auth_codes
  
  SELECT 'Tables created:' AS status;
SHOW TABLES;
 
SELECT 'Users seeded:' AS status;
SELECT id, username, email, role, created_at FROM users;
 
 USE securebank_db;

UPDATE users
SET  password_hash = '$2a$10$l82t9oMQp4zsIJ5UQcLgLebJ6zuS1wwKfMZBp.lvr163xD6MXsHHy', updated_at = now()
WHERE id=2;
