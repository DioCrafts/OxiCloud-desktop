use std::sync::{Arc, Mutex};
use std::time::Duration;
use chrono::Utc;

use anyhow::{Result, anyhow};
use log::{info, debug, error, warn};
use reqwest::{Client, Method, StatusCode, RequestBuilder, Response, header};
use serde::{Serialize, de::DeserializeOwned};

use crate::domain::models::user::AuthToken;

/// Wrapper around reqwest HTTP client with authentication management
pub struct HttpClient {
    /// The base URL for the OxiCloud server
    base_url: Arc<Mutex<String>>,
    
    /// The HTTP client from reqwest
    client: Client,
    
    /// The current authentication token
    auth_token: Arc<Mutex<Option<AuthToken>>>,
    
    /// Function to refresh the token when expired
    token_refresher: Option<Arc<dyn Fn() -> Result<AuthToken> + Send + Sync>>,
}

impl HttpClient {
    /// Create a new HTTP client
    pub fn new(base_url: String) -> Self {
        let client = Client::builder()
            .timeout(Duration::from_secs(30))
            .build()
            .expect("Failed to create HTTP client");
        
        Self {
            base_url: Arc::new(Mutex::new(base_url.trim_end_matches('/').to_string())),
            client,
            auth_token: Arc::new(Mutex::new(None)),
            token_refresher: None,
        }
    }
    
    /// Update the base URL
    pub fn set_base_url(&self, base_url: &str) {
        let mut guard = self.base_url.lock().unwrap();
        *guard = base_url.trim_end_matches('/').to_string();
        debug!("Updated base URL to: {}", *guard);
    }
    
    /// Set the authentication token for the client
    pub fn set_auth_token(&self, token: AuthToken) {
        let mut guard = self.auth_token.lock().unwrap();
        *guard = Some(token);
    }
    
    /// Set a function to refresh the token when it expires
    pub fn set_token_refresher<F>(&mut self, refresher: F)
    where
        F: Fn() -> Result<AuthToken> + Send + Sync + 'static,
    {
        self.token_refresher = Some(Arc::new(refresher));
    }
    
    /// Get the current authentication token, refreshing if expired
    async fn get_token(&self) -> Result<Option<AuthToken>> {
        let token = {
            let guard = self.auth_token.lock().unwrap();
            guard.clone()
        };
        
        if let Some(token) = token {
            // Check if token is expired
            if Utc::now() < token.expires_at {
                return Ok(Some(token));
            }
            
            // Token is expired, try to refresh
            if let Some(refresher) = &self.token_refresher {
                match refresher() {
                    Ok(new_token) => {
                        self.set_auth_token(new_token.clone());
                        return Ok(Some(new_token));
                    }
                    Err(e) => {
                        error!("Failed to refresh token: {}", e);
                        return Err(anyhow!("Failed to refresh token: {}", e));
                    }
                }
            }
        }
        
        Ok(None)
    }
    
    /// Create a new request with authentication
    async fn request(&self, method: Method, path: &str) -> Result<RequestBuilder> {
        let base_url = {
            let guard = self.base_url.lock().unwrap();
            guard.clone()
        };
        
        let url = format!("{}{}", base_url, path);
        let mut builder = self.client.request(method, &url);
        
        // Add authentication if available
        if let Ok(Some(token)) = self.get_token().await {
            builder = builder.header(
                header::AUTHORIZATION,
                format!("{} {}", token.token_type, token.access_token),
            );
        }
        
        Ok(builder)
    }
    
    /// Handle a response, checking for errors
    async fn handle_response(&self, response: Response) -> Result<Response> {
        match response.status() {
            StatusCode::OK | StatusCode::CREATED | StatusCode::ACCEPTED | StatusCode::NO_CONTENT => {
                Ok(response)
            }
            StatusCode::UNAUTHORIZED => {
                // Attempt to refresh token and retry
                error!("Unauthorized response (401)");
                Err(anyhow!("Unauthorized"))
            }
            status => {
                let body = response.text().await.unwrap_or_default();
                error!("HTTP error {}: {}", status, body);
                Err(anyhow!("HTTP error {}: {}", status, body))
            }
        }
    }
    
    /// Send a GET request
    pub async fn get<T>(&self, path: &str) -> Result<T>
    where
        T: DeserializeOwned,
    {
        let request = self.request(Method::GET, path).await?;
        let response = request.send().await?;
        let response = self.handle_response(response).await?;
        
        let data = response.json::<T>().await?;
        Ok(data)
    }
    
    /// Send a POST request with JSON body
    pub async fn post<T, U>(&self, path: &str, body: &T) -> Result<U>
    where
        T: Serialize,
        U: DeserializeOwned,
    {
        let request = self.request(Method::POST, path).await?;
        let response = request
            .header(header::CONTENT_TYPE, "application/json")
            .json(body)
            .send()
            .await?;
        
        let response = self.handle_response(response).await?;
        let data = response.json::<U>().await?;
        Ok(data)
    }
    
    /// Send a PUT request with JSON body
    pub async fn put<T, U>(&self, path: &str, body: &T) -> Result<U>
    where
        T: Serialize,
        U: DeserializeOwned,
    {
        let request = self.request(Method::PUT, path).await?;
        let response = request
            .header(header::CONTENT_TYPE, "application/json")
            .json(body)
            .send()
            .await?;
        
        let response = self.handle_response(response).await?;
        let data = response.json::<U>().await?;
        Ok(data)
    }
    
    /// Send a DELETE request
    pub async fn delete<T>(&self, path: &str) -> Result<T>
    where
        T: DeserializeOwned,
    {
        let request = self.request(Method::DELETE, path).await?;
        let response = request.send().await?;
        let response = self.handle_response(response).await?;
        
        let data = response.json::<T>().await?;
        Ok(data)
    }
    
    /// Send a request without expecting a JSON response
    pub async fn request_raw(&self, method: Method, path: &str) -> Result<RequestBuilder> {
        self.request(method, path).await
    }
    
    /// Send a request with binary data
    pub async fn request_with_body(&self, method: Method, path: &str, body: Vec<u8>, content_type: &str) -> Result<RequestBuilder> {
        let request = self.request(method, path).await?;
        Ok(request
            .header(header::CONTENT_TYPE, content_type)
            .body(body))
    }
}