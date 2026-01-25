import { Link } from "react-router-dom"
import { Crosshair, Plus } from "lucide-react"
import { Button } from "@/components/ui/button"

export function Header() {
  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="flex h-14 items-center px-6">
        <Link to="/" className="flex items-center gap-2">
          <Crosshair className="size-6" />
          <span className="font-bold">Node Generator</span>
        </Link>
        <div className="ml-auto flex items-center gap-4">
          <Button asChild>
            <Link to="/nodes/create">
              <Plus className="size-4" />
              Create Node
            </Link>
          </Button>
        </div>
      </div>
    </header>
  )
}
