ASM = nasm

SRC_DIR = src
BUILD_DIR = build

.PHONY: all floppy_image kernel bootloader clean always

# _________________________________________
# FORMAT MAKEFILE (INDENTATION)
# sed -i'.bak' 's/^  /\t/' Makefile

# _________________________________________
# FLOPPY IMAGE
# FAT FS Documentation: https://wiki.osdev.org/FAT
# FAT12 Disc Image Createion MacOS: https://apple.stackexchange.com/questions/465871/command-to-format-a-raw-floppy-disk-image-with-fat12
floppy_image: $(BUILD_DIR)/main_floppy.img
$(BUILD_DIR)/main_floppy.img: bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	hdiutil attach -nomount $(BUILD_DIR)/main_floppy.img
	newfs_msdos -F 12 -f 2880 -v NBOS disk2
	hdiutil detach disk2
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"

  # _________________________________________
  # Run mdir -i build/main_floppy.img after the build to check if the disc contains the kernel.

	# _________________________________________
	# FLOPPY IMAGE CREATION FROM TUTORIAL TWO:
	# dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	# mkfs.fat -F 12 -n "NBOS" $(BUILD_DIR)/main_floppy.img
	# dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	# mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"

	# _________________________________________
	# FLOPPY IMAGE CREATION FROM TUTORIAL ONE:
	# cp $(BUILD_DIR)/main.bin $(BUILD_DIR)/main_floppy.img
	# truncate -s 1440k $(BUILD_DIR)/main_floppy.img

# _________________________________________
# BOOTLOADER
bootloader: $(BUILD_DIR)/bootloader.bin
$(BUILD_DIR)/bootloader.bin: always
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin

# _________________________________________
# KERNEL
kernel: $(BUILD_DIR)/kernel.bin
$(BUILD_DIR)/kernel.bin: always
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin

# _________________________________________
# ALWAYS
always:
	mkdir -p $(BUILD_DIR)

# _________________________________________
# CLEAN
clean: 
	rm -rf $(BUILD_DIR)/*
