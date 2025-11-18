CREATE TABLE IF NOT EXISTS `thd_vehicle_stats` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `model` VARCHAR(60) NOT NULL UNIQUE,
    `max_speed` INT NOT NULL,
    `acceleration` INT NOT NULL,
    `braking` INT NOT NULL,
    `handling` INT NOT NULL
);
