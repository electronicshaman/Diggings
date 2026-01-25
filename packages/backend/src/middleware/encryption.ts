/**
 * Simple encryption/decryption for API keys
 *
 * SECURITY NOTE: Currently uses base64 encoding for development.
 * TODO: Upgrade to AES-256-GCM encryption in production.
 *
 * For production, consider:
 * - Using node:crypto with AES-256-GCM
 * - Storing encryption key in environment variable (ENCRYPTION_KEY)
 * - Rotating encryption keys periodically
 * - Using a key management service (AWS KMS, HashiCorp Vault, etc.)
 */

/**
 * Encrypt an API key for storage
 * @param plaintext - The API key to encrypt
 * @returns Base64-encoded string
 */
export function encryptApiKey(plaintext: string): string {
  // TODO: Replace with proper AES-256-GCM encryption
  return Buffer.from(plaintext).toString('base64');
}

/**
 * Decrypt an API key from storage
 * @param ciphertext - The encrypted API key
 * @returns Decrypted API key
 */
export function decryptApiKey(ciphertext: string): string {
  // TODO: Replace with proper AES-256-GCM decryption
  return Buffer.from(ciphertext, 'base64').toString('utf-8');
}

/**
 * Check if encryption is available
 * @returns true if encryption is configured
 */
export function isEncryptionConfigured(): boolean {
  // TODO: Check for ENCRYPTION_KEY environment variable
  return true; // Always true for base64 encoding
}

/**
 * Get encryption algorithm info
 * @returns Description of encryption method
 */
export function getEncryptionInfo(): { algorithm: string; strength: string; production: boolean } {
  // TODO: Update when AES-256-GCM is implemented
  return {
    algorithm: 'base64',
    strength: 'development-only',
    production: false,
  };
}
