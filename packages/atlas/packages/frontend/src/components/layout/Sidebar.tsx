import { NavLink } from "react-router-dom"
import { LayoutGrid, Settings, Wrench, Sparkles, Sliders } from "lucide-react"
import { cn } from "@/lib/utils"

const navigation = [
  { name: "All Nodes", href: "/nodes", icon: LayoutGrid },
  { name: "AI Generate", href: "/generate", icon: Sparkles },
  { name: "Configuration", href: "/config", icon: Settings },
  { name: "Advanced Config", href: "/config/advanced", icon: Sliders },
  { name: "Settings", href: "/settings", icon: Wrench },
]

export function Sidebar() {
  return (
    <aside className="hidden w-64 shrink-0 border-r bg-muted/40 md:block">
      <nav className="flex flex-col gap-1 p-4">
        {navigation.map((item) => (
          <NavLink
            key={item.name}
            to={item.href}
            className={({ isActive }) =>
              cn(
                "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors",
                isActive
                  ? "bg-primary text-primary-foreground"
                  : "text-muted-foreground hover:bg-muted hover:text-foreground"
              )
            }
          >
            <item.icon className="size-4" />
            {item.name}
          </NavLink>
        ))}
      </nav>
    </aside>
  )
}
