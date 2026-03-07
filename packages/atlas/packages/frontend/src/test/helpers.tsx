import {
  QueryClient,
  QueryClientProvider,
  type DefaultOptions,
} from "@tanstack/react-query"
import {
  render,
  renderHook,
  type RenderOptions,
} from "@testing-library/react"
import type { ReactElement, ReactNode } from "react"
import { MemoryRouter } from "react-router-dom"

interface ProviderOptions {
  initialEntries?: string[]
  queryClient?: QueryClient
}

interface RenderHookWithProvidersOptions<Props> extends ProviderOptions {
  initialProps?: Props
}

interface WrapperProps {
  children: ReactNode
}

const defaultQueryOptions: DefaultOptions = {
  queries: {
    retry: false,
    gcTime: Infinity,
  },
  mutations: {
    retry: false,
  },
}

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: defaultQueryOptions,
  })
}

function createWrapper(options: ProviderOptions) {
  const queryClient = options.queryClient ?? createTestQueryClient()
  const initialEntries = options.initialEntries ?? ["/"]

  function Wrapper({ children }: WrapperProps) {
    return (
      <QueryClientProvider client={queryClient}>
        <MemoryRouter
          future={{
            v7_startTransition: true,
            v7_relativeSplatPath: true,
          }}
          initialEntries={initialEntries}
        >
          {children}
        </MemoryRouter>
      </QueryClientProvider>
    )
  }

  return {
    queryClient,
    Wrapper,
  }
}

export function renderWithProviders(
  ui: ReactElement,
  options: ProviderOptions & Omit<RenderOptions, "wrapper"> = {}
) {
  const { initialEntries, queryClient: providedQueryClient, ...renderOptions } = options
  const { queryClient, Wrapper } = createWrapper({
    initialEntries,
    queryClient: providedQueryClient,
  })

  return {
    queryClient,
    ...render(ui, {
      wrapper: Wrapper,
      ...renderOptions,
    }),
  }
}

export function renderHookWithProviders<Result, Props>(
  renderCallback: (initialProps: Props) => Result,
  options: RenderHookWithProvidersOptions<Props> = {}
) {
  const {
    initialEntries,
    queryClient: providedQueryClient,
    ...renderHookOptions
  } = options
  const { queryClient, Wrapper } = createWrapper({
    initialEntries,
    queryClient: providedQueryClient,
  })

  return {
    queryClient,
    ...renderHook(renderCallback, {
      wrapper: Wrapper,
      ...renderHookOptions,
    }),
  }
}
