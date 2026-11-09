// Registry of the phone screens, keyed by the `screen` field of src/data/chapters.js.
import home from './home.js'
import lockscreen from './lockscreen.js'
import onboarding from './onboarding.js'
import login from './login.js'
import addItem from './add-item.js'
import extensionLink from './extension-link.js'
import wishlist from './wishlist.js'
import reviewWait from './review-wait.js'
import prePurchase from './pre-purchase.js'
import recordPurchase from './record-purchase.js'
import budget from './budget.js'
import patterns from './patterns.js'
import insights from './insights.js'
import reflection from './reflection.js'
import profile from './profile.js'
import history from './history.js'
import bubble from './bubble.js'

export const screens = Object.fromEntries(
  [home, lockscreen, onboarding, login, addItem, extensionLink, wishlist, reviewWait, prePurchase, recordPurchase, budget, patterns, insights, reflection, profile, history, bubble].map((m) => [m.id, m]),
)
