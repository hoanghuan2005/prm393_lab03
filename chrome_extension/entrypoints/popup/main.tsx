import { createRoot } from 'react-dom/client';
import '../../assets/tokens.css';
import './popup.css';
import App from './App';
import { SyncBanner } from '../../components/SyncBanner';
createRoot(document.getElementById('root')!).render(<><SyncBanner /><App /></>);
