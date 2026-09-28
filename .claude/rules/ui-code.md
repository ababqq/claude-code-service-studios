---
paths:
  - "**/src/components/**"
  - "**/src/app/**"
  - "**/src/pages/**"
  - "**/src/screens/**"
  - "**/lib/**/widgets/**"
  - "apps/*/app/**"
  - "apps/*/components/**"
  - "apps/*/screens/**"
  - "packages/*/src/components/**"
---

# UI Code Rules

These paths hold screens, routes and components for web and mobile. The UX spec for the screen
(`design/ux/<slug>.md`) says what it does, the app shell (`design/ux/app-shell.md`) says where it sits, and the
design language (`design/brand/design-language.md`) says what it looks like. Styling follows
`.claude/rules/styles-code.md`; mobile code roots also follow `.claude/rules/mobile-code.md`.

## Design-language components only

- Build screens from the component library (for example `packages/ui`), themed by tokens. No one-off restyled
  native elements, no copied-and-tweaked components, no second button. A missing component or variant is a request
  to the `design-engineer`, not an inline improvisation.
- Icons and illustrations come from the design language's sets, sized by tokens.
- Destructive and money-moving actions (cancel subscription, delete account, confirm deposit) use the confirmation
  pattern of the design language's `### Confirmation for Destructive and Money-Moving Actions`.

## Every state, every time

- Each screen and data-driven component implements the states its UX spec lists — at minimum **loading, empty,
  error and offline**, plus partial data, permission denied and session expired where they can occur.
- Loading reserves the final layout (skeletons with fixed dimensions) so content does not shift (CLS within
  `performance.cls`); spinners that block the whole screen are for actions, not for data.
- Empty states tell the user what to do next. Error states say what happened and offer a retry or a way out; each
  API problem `code` maps to a reviewed message (`.claude/rules/content-copy.md`), never to the raw response.
- Offline: the app shell's global offline state is shown; queued actions show as pending; actions that need the
  network (payments, deposits) are disabled with an explanation rather than failing after the tap.
- A state is not done until it has been seen: UI stories retain a screenshot of each state touched under
  `production/qa/evidence/<story-slug>/` (`.claude/docs/run-and-observe.md`).

## Accessibility

- Semantic structure first: native elements and platform controls (`<button>`, `<a href>`, `<label>`, headings in
  order, landmarks) before ARIA; a `div` with `onClick` is a defect.
- Every control has an accessible name — visible label, `aria-label` for icon-only buttons,
  `accessibilityLabel` (React Native), `contentDescription` (Android), `.accessibilityLabel` (SwiftUI), `Semantics`
  (Flutter). Form fields have visible labels; errors are tied to their field (`aria-describedby`) and announced.
- Keyboard and screen reader operable: logical tab order, no keyboard traps, dialogs trap focus while open and
  return it on close, focus moves to the new content on route change, and toasts are announced via a live region.
- Touch targets meet WCAG 2.2 SC 2.5.8 (at least 24×24 CSS px) and the platform guidance on mobile (44×44 pt on iOS,
  48×48 dp on Android). Text scales with the user's setting (Dynamic Type, Android font scale, browser zoom to
  200%) without clipping.
- Motion respects reduced-motion preferences and can be skipped; nothing flashes.
- The level to meet is `accessibility.target` (and the screen's `design/accessibility-requirements.md`
  commitments); unset ⇒ ask, unset is not `none`. Component tests run an automated check (axe, or the platform's
  accessibility audit) and the result is kept with the UI story's evidence.

## Internationalization

- Every user-facing string goes through the i18n layer — no hardcoded text, including `alt`, `aria-label`,
  placeholder and error strings. Keys and plural rules follow `.claude/rules/content-copy.md`.
- Numbers, currency, dates and relative times are formatted with the locale APIs (`Intl.NumberFormat`,
  `Intl.DateTimeFormat`, platform formatters), never by string building: KRW shows no decimals, and dates show in
  the user's time zone.
- Layouts tolerate longer translations and right-to-left scripts (logical properties, no fixed-width text boxes).

## No business logic in views

- Views render state and emit intents. Prices, limits, eligibility, fees and plan entitlements come from the API —
  the UI never recomputes them as the source of truth, and never shows a money-moving amount the server has not
  confirmed.
- Data fetching lives in route loaders, server components, query hooks or view models — not scattered through
  presentational components. Presentational components are pure functions of their props.
- Client-side validation mirrors the contract for fast feedback; the server remains the authority.
- Nothing secret reaches the client bundle: only public configuration is exposed (for example `NEXT_PUBLIC_`
  variables); tokens stay in secure, httpOnly storage on the web and in the Keychain/Keystore on mobile. Never
  render unsanitized HTML (`dangerouslySetInnerHTML`, `v-html`) from user or API content.

## Responsiveness and performance

- Test every screen at the smallest and largest supported viewport or device, in both themes, at 200% text size.
- The main thread stays free: long work goes to a worker, a background task or the server; lists are virtualized;
  images are sized (`width`/`height` or aspect ratio) and lazy-loaded below the fold; routes are code-split so
  initial JavaScript stays within `performance.bundle_kb`, and LCP and INP within `performance.lcp_ms` and
  `performance.inp_ms`.

## Examples

**Correct** (React + TypeScript — Moa goal list; library components, all four states, i18n, no business logic):

```tsx
export function GoalList() {
  const { t } = useTranslation('goals');
  const { data, status, refetch } = useGoals();         // data fetching in a hook, not in the view
  const online = useOnlineStatus();

  if (!online && !data) return <OfflineState onRetry={refetch} />;
  if (status === 'pending') return <GoalListSkeleton rows={3} />;
  if (status === 'error') return <ErrorState title={t('list.error.title')} onRetry={refetch} />;
  if (data.goals.length === 0) {
    return <EmptyState title={t('list.empty.title')} action={<Button href="/goals/new">{t('list.empty.cta')}</Button>} />;
  }
  return (
    <List aria-label={t('list.label')}>
      {data.goals.map((goal) => (
        <GoalCard key={goal.id} goal={goal} canCreateMore={data.limits.canCreate} /> // limit decided by the API
      ))}
    </List>
  );
}
```

**Incorrect**:

```tsx
export function GoalList({ user }) {
  const [goals, setGoals] = useState([]);
  useEffect(() => { fetch('/api/goals').then((r) => r.json()).then(setGoals); }, []); // VIOLATION: no loading, error
                                                                                        //   or offline state
  const canCreate = user.plan === 'free' ? goals.length < 3 : true;  // VIOLATION: plan limit recomputed in the view
  return (
    <div>
      {goals.length === 0 && <p>목표가 없습니다</p>}                   {/* VIOLATION: hardcoded string, no next action */}
      <div className="add" onClick={() => router.push('/goals/new')}> {/* VIOLATION: div as a button; no name, no keyboard */}
        <PlusIcon />
      </div>
    </div>
  );
}
```
