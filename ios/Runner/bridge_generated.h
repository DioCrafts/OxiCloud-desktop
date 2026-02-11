#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
// EXTRA BEGIN
typedef struct DartCObject *WireSyncRust2DartDco;
typedef struct WireSyncRust2DartSse {
  uint8_t *ptr;
  int32_t len;
} WireSyncRust2DartSse;

typedef int64_t DartPort;
typedef bool (*DartPostCObjectFnType)(DartPort port_id, void *message);
void store_dart_post_cobject(DartPostCObjectFnType ptr);
// EXTRA END
typedef struct _Dart_Handle* Dart_Handle;

typedef struct wire_cst_list_prim_u_8_strict {
  uint8_t *ptr;
  int32_t len;
} wire_cst_list_prim_u_8_strict;

typedef struct wire_cst_list_String {
  struct wire_cst_list_prim_u_8_strict **ptr;
  int32_t len;
} wire_cst_list_String;

typedef struct wire_cst_sync_config {
  struct wire_cst_list_prim_u_8_strict *sync_folder;
  struct wire_cst_list_prim_u_8_strict *database_path;
  uint32_t sync_interval_seconds;
  uint32_t max_upload_speed_kbps;
  uint32_t max_download_speed_kbps;
  bool delta_sync_enabled;
  uint64_t delta_sync_min_size;
  bool pause_on_metered;
  bool wifi_only;
  bool watch_filesystem;
  struct wire_cst_list_String *ignore_patterns;
  bool notifications_enabled;
  bool launch_at_startup;
  bool minimize_to_tray;
} wire_cst_sync_config;

typedef struct wire_cst_conflict_info {
  int32_t conflict_type;
  int64_t detected_at;
} wire_cst_conflict_info;

typedef struct wire_cst_server_info {
  struct wire_cst_list_prim_u_8_strict *url;
  struct wire_cst_list_prim_u_8_strict *version;
  struct wire_cst_list_prim_u_8_strict *name;
  struct wire_cst_list_prim_u_8_strict *webdav_url;
  uint64_t quota_total;
  uint64_t quota_used;
  bool supports_delta_sync;
  bool supports_chunked_upload;
} wire_cst_server_info;

typedef struct wire_cst_remote_folder {
  struct wire_cst_list_prim_u_8_strict *id;
  struct wire_cst_list_prim_u_8_strict *name;
  struct wire_cst_list_prim_u_8_strict *path;
  uint64_t size_bytes;
  uint32_t item_count;
  bool is_selected;
} wire_cst_remote_folder;

typedef struct wire_cst_list_remote_folder {
  struct wire_cst_remote_folder *ptr;
  int32_t len;
} wire_cst_list_remote_folder;

typedef struct wire_cst_sync_conflict {
  struct wire_cst_list_prim_u_8_strict *id;
  struct wire_cst_list_prim_u_8_strict *item_path;
  int64_t local_modified;
  int64_t remote_modified;
  uint64_t local_size;
  uint64_t remote_size;
  int32_t conflict_type;
} wire_cst_sync_conflict;

typedef struct wire_cst_list_sync_conflict {
  struct wire_cst_sync_conflict *ptr;
  int32_t len;
} wire_cst_list_sync_conflict;

typedef struct wire_cst_sync_history_entry {
  struct wire_cst_list_prim_u_8_strict *id;
  int64_t timestamp;
  struct wire_cst_list_prim_u_8_strict *operation;
  struct wire_cst_list_prim_u_8_strict *item_path;
  struct wire_cst_list_prim_u_8_strict *direction;
  struct wire_cst_list_prim_u_8_strict *status;
  struct wire_cst_list_prim_u_8_strict *error_message;
} wire_cst_sync_history_entry;

typedef struct wire_cst_list_sync_history_entry {
  struct wire_cst_sync_history_entry *ptr;
  int32_t len;
} wire_cst_list_sync_history_entry;

typedef struct wire_cst_SyncStatus_Conflict {
  struct wire_cst_conflict_info *field0;
} wire_cst_SyncStatus_Conflict;

typedef struct wire_cst_SyncStatus_Error {
  struct wire_cst_list_prim_u_8_strict *field0;
} wire_cst_SyncStatus_Error;

typedef union SyncStatusKind {
  struct wire_cst_SyncStatus_Conflict Conflict;
  struct wire_cst_SyncStatus_Error Error;
} SyncStatusKind;

typedef struct wire_cst_sync_status {
  int32_t tag;
  union SyncStatusKind kind;
} wire_cst_sync_status;

typedef struct wire_cst_sync_item {
  struct wire_cst_list_prim_u_8_strict *id;
  struct wire_cst_list_prim_u_8_strict *path;
  struct wire_cst_list_prim_u_8_strict *name;
  bool is_directory;
  uint64_t size;
  struct wire_cst_list_prim_u_8_strict *content_hash;
  int64_t *local_modified;
  int64_t *remote_modified;
  struct wire_cst_sync_status status;
  int32_t direction;
  struct wire_cst_list_prim_u_8_strict *etag;
  struct wire_cst_list_prim_u_8_strict *mime_type;
} wire_cst_sync_item;

typedef struct wire_cst_list_sync_item {
  struct wire_cst_sync_item *ptr;
  int32_t len;
} wire_cst_list_sync_item;

typedef struct wire_cst_auth_result {
  bool success;
  struct wire_cst_list_prim_u_8_strict *user_id;
  struct wire_cst_list_prim_u_8_strict *username;
  struct wire_cst_server_info server_info;
  struct wire_cst_list_prim_u_8_strict *access_token;
} wire_cst_auth_result;

typedef struct wire_cst_sync_result {
  bool success;
  uint32_t items_uploaded;
  uint32_t items_downloaded;
  uint32_t items_deleted;
  uint32_t conflicts;
  struct wire_cst_list_String *errors;
  uint64_t duration_ms;
} wire_cst_sync_result;

typedef struct wire_cst_sync_status_info {
  bool is_syncing;
  struct wire_cst_list_prim_u_8_strict *current_operation;
  float progress_percent;
  uint32_t items_synced;
  uint32_t items_total;
  int64_t *last_sync_time;
  int64_t *next_sync_time;
} wire_cst_sync_status_info;

void frbgen_oxicloud_app_wire__crate__api__oxicloud__get_config(int64_t port_);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__get_conflicts(int64_t port_);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__get_pending_items(int64_t port_);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__get_remote_folders(int64_t port_);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__get_server_info(int64_t port_);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__get_sync_folders(int64_t port_);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__get_sync_history(int64_t port_,
                                                                      uint32_t limit);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__get_sync_status(int64_t port_);

WireSyncRust2DartDco frbgen_oxicloud_app_wire__crate__api__simple__greet(struct wire_cst_list_prim_u_8_strict *name);

void frbgen_oxicloud_app_wire__crate__api__simple__init_app(int64_t port_);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__initialize(int64_t port_,
                                                                struct wire_cst_sync_config *config);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__is_logged_in(int64_t port_);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__login(int64_t port_,
                                                           struct wire_cst_list_prim_u_8_strict *server_url,
                                                           struct wire_cst_list_prim_u_8_strict *username,
                                                           struct wire_cst_list_prim_u_8_strict *password);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__logout(int64_t port_);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__resolve_conflict(int64_t port_,
                                                                      struct wire_cst_list_prim_u_8_strict *conflict_id,
                                                                      int32_t resolution);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__set_sync_folders(int64_t port_,
                                                                      struct wire_cst_list_String *folder_ids);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__shutdown(int64_t port_);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__start_sync(int64_t port_);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__stop_sync(int64_t port_);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__sync_now(int64_t port_);

void frbgen_oxicloud_app_wire__crate__api__oxicloud__update_config(int64_t port_,
                                                                   struct wire_cst_sync_config *config);

int64_t *frbgen_oxicloud_app_cst_new_box_autoadd_Chrono_Utc(int64_t value);

struct wire_cst_conflict_info *frbgen_oxicloud_app_cst_new_box_autoadd_conflict_info(void);

int64_t *frbgen_oxicloud_app_cst_new_box_autoadd_i_64(int64_t value);

struct wire_cst_server_info *frbgen_oxicloud_app_cst_new_box_autoadd_server_info(void);

struct wire_cst_sync_config *frbgen_oxicloud_app_cst_new_box_autoadd_sync_config(void);

struct wire_cst_list_String *frbgen_oxicloud_app_cst_new_list_String(int32_t len);

struct wire_cst_list_prim_u_8_strict *frbgen_oxicloud_app_cst_new_list_prim_u_8_strict(int32_t len);

struct wire_cst_list_remote_folder *frbgen_oxicloud_app_cst_new_list_remote_folder(int32_t len);

struct wire_cst_list_sync_conflict *frbgen_oxicloud_app_cst_new_list_sync_conflict(int32_t len);

struct wire_cst_list_sync_history_entry *frbgen_oxicloud_app_cst_new_list_sync_history_entry(int32_t len);

struct wire_cst_list_sync_item *frbgen_oxicloud_app_cst_new_list_sync_item(int32_t len);
static int64_t dummy_method_to_enforce_bundling(void) {
    int64_t dummy_var = 0;
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_cst_new_box_autoadd_Chrono_Utc);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_cst_new_box_autoadd_conflict_info);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_cst_new_box_autoadd_i_64);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_cst_new_box_autoadd_server_info);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_cst_new_box_autoadd_sync_config);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_cst_new_list_String);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_cst_new_list_prim_u_8_strict);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_cst_new_list_remote_folder);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_cst_new_list_sync_conflict);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_cst_new_list_sync_history_entry);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_cst_new_list_sync_item);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__get_config);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__get_conflicts);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__get_pending_items);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__get_remote_folders);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__get_server_info);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__get_sync_folders);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__get_sync_history);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__get_sync_status);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__initialize);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__is_logged_in);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__login);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__logout);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__resolve_conflict);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__set_sync_folders);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__shutdown);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__start_sync);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__stop_sync);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__sync_now);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__oxicloud__update_config);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__simple__greet);
    dummy_var ^= ((int64_t) (void*) frbgen_oxicloud_app_wire__crate__api__simple__init_app);
    dummy_var ^= ((int64_t) (void*) store_dart_post_cobject);
    return dummy_var;
}
