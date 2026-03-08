import { Routes, Route } from 'react-router-dom'
import { Layout } from './components/layout/Layout'
import { ErrorBoundary } from './components/ErrorBoundary'
import { NodeListPage } from './routes/nodes/list'
import { NodeDetailPage } from './routes/nodes/detail'
import { NodeCreatePage } from './routes/nodes/create'
import { NodeEditPage } from './routes/nodes/edit'
import { ConfigPage } from './routes/config'
import { AdvancedConfigPage } from './routes/config/advanced'
import SettingsPage from './routes/settings'
import GeneratePage from './routes/generate'
import { CardListPage } from './routes/cards/list'
import { CardCreatePage } from './routes/cards/create'
import { CardDetailPage } from './routes/cards/detail'
import { CardEditPage } from './routes/cards/edit'

export default function App() {
  return (
    <ErrorBoundary>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<NodeListPage />} />
          <Route path="/nodes" element={<NodeListPage />} />
          <Route path="/nodes/create" element={<NodeCreatePage />} />
          <Route path="/nodes/:id" element={<NodeDetailPage />} />
          <Route path="/nodes/:id/edit" element={<NodeEditPage />} />
          <Route path="/config" element={<ConfigPage />} />
          <Route path="/config/advanced" element={<AdvancedConfigPage />} />
          <Route path="/settings" element={<SettingsPage />} />
          <Route path="/generate" element={<GeneratePage />} />
          <Route path="/cards" element={<CardListPage />} />
          <Route path="/cards/create" element={<CardCreatePage />} />
          <Route path="/cards/:id" element={<CardDetailPage />} />
          <Route path="/cards/:id/edit" element={<CardEditPage />} />
        </Route>
      </Routes>
    </ErrorBoundary>
  )
}
