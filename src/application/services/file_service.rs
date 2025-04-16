use async_trait::async_trait;
use std::path::Path;
use std::sync::Arc;

use crate::application::dtos::file_dto::{FileDto, FileTypeDto, SyncStatusDto};
use crate::application::ports::file_port::{FilePort, FileResult};
use crate::domain::entities::file::{FileType, SyncStatus};
use crate::domain::services::file_service::FileService;

pub struct FileApplicationService {
    file_service: Arc<dyn FileService>,
}

impl FileApplicationService {
    pub fn new(file_service: Arc<dyn FileService>) -> Self {
        Self { file_service }
    }

    fn map_file_type(file_type: FileType) -> FileTypeDto {
        match file_type {
            FileType::File => FileTypeDto::File,
            FileType::Directory => FileTypeDto::Directory,
        }
    }

    fn map_sync_status(status: SyncStatus) -> SyncStatusDto {
        match status {
            SyncStatus::Synced => SyncStatusDto::Synced,
            SyncStatus::Syncing => SyncStatusDto::Syncing,
            SyncStatus::PendingUpload => SyncStatusDto::PendingUpload,
            SyncStatus::PendingDownload => SyncStatusDto::PendingDownload,
            SyncStatus::Error => SyncStatusDto::Error,
            SyncStatus::Conflicted => SyncStatusDto::Conflicted,
            SyncStatus::Ignored => SyncStatusDto::Ignored,
        }
    }

    fn map_domain_to_dto(file: &crate::domain::entities::file::FileItem) -> FileDto {
        FileDto {
            id: file.id.clone(),
            name: file.name.clone(),
            path: file.path.clone(),
            file_type: Self::map_file_type(file.file_type.clone()),
            size: file.size,
            mime_type: file.mime_type.clone(),
            parent_id: file.parent_id.clone(),
            created_at: file.created_at,
            modified_at: file.modified_at,
            sync_status: Self::map_sync_status(file.sync_status.clone()),
            is_favorite: file.is_favorite,
            local_path: file.local_path.clone(),
        }
    }
}

#[async_trait]
impl FilePort for FileApplicationService {
    async fn get_file(&self, file_id: &str) -> FileResult<FileDto> {
        let file = self.file_service.get_file(file_id).await?;
        Ok(Self::map_domain_to_dto(&file))
    }

    async fn list_files(&self, folder_id: Option<&str>) -> FileResult<Vec<FileDto>> {
        let files = self.file_service.list_files(folder_id).await?;
        Ok(files.iter().map(|f| Self::map_domain_to_dto(f)).collect())
    }

    async fn get_file_content(&self, file_id: &str) -> FileResult<Vec<u8>> {
        self.file_service.get_file_content(file_id).await
    }

    async fn create_file(&self, name: &str, folder_id: Option<&str>, content: Vec<u8>) -> FileResult<FileDto> {
        let file = self.file_service.create_file(name, folder_id, content).await?;
        Ok(Self::map_domain_to_dto(&file))
    }

    async fn create_folder(&self, name: &str, parent_id: Option<&str>) -> FileResult<FileDto> {
        let folder = self.file_service.create_folder(name, parent_id).await?;
        Ok(Self::map_domain_to_dto(&folder))
    }

    async fn rename_item(&self, item_id: &str, new_name: &str) -> FileResult<FileDto> {
        let file = self.file_service.rename_item(item_id, new_name).await?;
        Ok(Self::map_domain_to_dto(&file))
    }

    async fn move_item(&self, item_id: &str, target_folder_id: Option<&str>) -> FileResult<FileDto> {
        let file = self.file_service.move_item(item_id, target_folder_id).await?;
        Ok(Self::map_domain_to_dto(&file))
    }

    async fn delete_item(&self, item_id: &str) -> FileResult<()> {
        self.file_service.delete_item(item_id).await
    }

    async fn get_favorites(&self) -> FileResult<Vec<FileDto>> {
        let files = self.file_service.get_favorites().await?;
        Ok(files.iter().map(|f| Self::map_domain_to_dto(f)).collect())
    }

    async fn toggle_favorite(&self, file_id: &str) -> FileResult<FileDto> {
        let file = self.file_service.toggle_favorite(file_id).await?;
        Ok(Self::map_domain_to_dto(&file))
    }

    async fn search_files(&self, query: &str) -> FileResult<Vec<FileDto>> {
        let files = self.file_service.search_files(query).await?;
        Ok(files.iter().map(|f| Self::map_domain_to_dto(f)).collect())
    }

    async fn upload_local_file(&self, path: &Path, parent_id: Option<&str>) -> FileResult<FileDto> {
        let file = self.file_service.upload_from_path(path, parent_id).await?;
        Ok(Self::map_domain_to_dto(&file))
    }

    async fn download_file(&self, file_id: &str, target_path: &Path) -> FileResult<()> {
        self.file_service.download_to_path(file_id, target_path).await
    }
}