#ifndef __SSD1307_H__
#define __SSD1307_H__


struct ssd1307_platform_data {
	/* Wiring information */
	uint32_t gpio_dio;
	uint32_t gpio_sclk;
	uint32_t gpio_stb;
	uint32_t gpio_12power;

	uint32_t GPIOlock;  // Make case: 0 - GPIO will be unlocked (will not be requested by kernel) 
	struct mutex *spi_lock_mutex;
};

#endif //#ifndef __SSD1307_H__

