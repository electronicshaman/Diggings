import { Copy } from 'lucide-react'
import { toast, type ExternalToast } from 'sonner'

/**
 * Error toast with a copy-to-clipboard action button.
 * Copies the message (and description if present) to the clipboard.
 */
export function errorToast(
  message: string,
  options?: ExternalToast & { copyText?: string }
) {
  const { copyText, ...sonnerOptions } = options ?? {}

  const textToCopy =
    copyText ??
    (sonnerOptions.description && typeof sonnerOptions.description === 'string'
      ? `${message}\n${sonnerOptions.description}`
      : message)

  toast.error(message, {
    ...sonnerOptions,
    action: {
      label: (
        <Copy className="!size-3.5" />
      ),
      onClick: () => void navigator.clipboard.writeText(textToCopy),
    },
  })
}
