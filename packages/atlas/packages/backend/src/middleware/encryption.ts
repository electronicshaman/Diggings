/**
 * AES-256-GCM encryption/decryption for API keys
 *
 * Requires ENCRYPTION_KEY environment variable (32+ character string).
 * Falls back to base64 encoding in development when no key is set.
 */

import { createCipheriv, createDecipheriv, randomBytes, scryptSync } from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12;
const TAG_LENGTH = 16;
const SALT = 'node-gen-web-salt'; // Static salt is fine when key is already high-entropy

function getEncryptionKey(): Buffer | null {
  const envKey = process.env.ENCRYPTION_KEY;
  if (!envKey) return null;
  return scryptSync(envKey, SALT, 32);
}

/**
 * Encrypt an API key for storage
 * @param plaintext - The API key to encrypt
 * @returns Encrypted string (base64-encoded iv:tag:ciphertext) or base64-only in dev
 */
export function encryptApiKey(plaintext: string): string {
  const key = getEncryptionKey();
  if (!key) {
    // Development fallback - base64 only
    return Buffer.from(plaintext).toString('base64');
  }

  const iv = randomBytes(IV_LENGTH);
  const cipher = createCipheriv(ALGORITHM, key, iv);

  let encrypted = cipher.update(plaintext, 'utf-8');
  encrypted = Buffer.concat([encrypted, cipher.final()]);
  const tag = cipher.getAuthTag();

  // Format: iv:tag:ciphertext (all base64)
  return `enc:${iv.toString('base64')}:${tag.toString('base64')}:${encrypted.toString('base64')}`;
}

/**
 * Decrypt an API key from storage
 * @param ciphertext - The encrypted API key
 * @returns Decrypted API key
 */
export function decryptApiKey(ciphertext: string): string {
  // Handle legacy base64-only values
  if (!ciphertext.startsWith('enc:')) {
    return Buffer.from(ciphertext, 'base64').toString('utf-8');
  }

  const key = getEncryptionKey();
  if (!key) {
    throw new Error('ENCRYPTION_KEY is required to decrypt API keys encrypted with AES-256-GCM');
  }

  const parts = ciphertext.split(':');
  if (parts.length !== 4) {
    throw new Error('Invalid encrypted value format');
  }

  const iv = Buffer.from(parts[1], 'base64');
  const tag = Buffer.from(parts[2], 'base64');
  const encrypted = Buffer.from(parts[3], 'base64');

  const decipher = createDecipheriv(ALGORITHM, key, iv);
  decipher.setAuthTag(tag);

  let decrypted = decipher.update(encrypted);
  decrypted = Buffer.concat([decrypted, decipher.final()]);

  return decrypted.toString('utf-8');
}

/**
 * Check if encryption is available
 * @returns true if ENCRYPTION_KEY is configured
 */
export function isEncryptionConfigured(): boolean {
  return !!process.env.ENCRYPTION_KEY;
}

/**
 * Get encryption algorithm info
 * @returns Description of encryption method
 */
export function getEncryptionInfo(): { algorithm: string; strength: string; production: boolean } {
  if (isEncryptionConfigured()) {
    return {
      algorithm: 'aes-256-gcm',
      strength: 'production',
      production: true,
    };
  }

  return {
    algorithm: 'base64',
    strength: 'development-only',
    production: false,
  };
}
