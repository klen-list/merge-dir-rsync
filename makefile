TARGET_DIR := target_dir
SRC_DIR1 := source1
SRC_DIR2 := source2
SRC_DIR3 := source3

start:
	@pkill -q -f sync.sh || true
	@./check-sync.sh
	@echo "[Sync] Merge folders into $(TARGET_DIR)..."
	@rm -rf $(TARGET_DIR)
	@mkdir $(TARGET_DIR)
	@cp -R $(SRC_DIR1)/* $(TARGET_DIR)/ 2>/dev/null || true
	@cp -R $(SRC_DIR2)/* $(TARGET_DIR)/ 2>/dev/null || true
	@./sync.sh &
	@echo "[Sync] Merge - Done."

stop:
	@echo "[Sync] Stop filewatcher..."
	@pkill -q -f sync.sh || true
	@./check-sync.sh
	@echo "[Sync] Removing $(TARGET_DIR)..."
	@rm -rf $(TARGET_DIR)
	@echo "Stop - Done."