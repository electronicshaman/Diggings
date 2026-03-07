import { Sparkles, Wand2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';

interface FieldAssistButtonProps {
  onClick: () => void;
  isLoading?: boolean;
  disabled?: boolean;
  tooltip?: string;
}

export function FieldAssistButton({
  onClick,
  isLoading,
  disabled,
  tooltip = 'Generate with AI'
}: FieldAssistButtonProps) {
  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="size-8"
            onClick={onClick}
            disabled={isLoading || disabled}
            aria-label={tooltip}
          >
            {isLoading ? (
              <Sparkles className="size-4 animate-pulse" />
            ) : (
              <Wand2 className="size-4" />
            )}
          </Button>
        </TooltipTrigger>
        <TooltipContent>
          <p>{tooltip}</p>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}
