# Design System Specification: Luminous Depth

## 1. Overview & Creative North Star
**The Creative North Star: "The Neon Observatory"**

This design system rejects the "flatness" of modern SaaS. It is an editorial exploration of light within an infinite void. Instead of treating the screen as a 2D surface, we treat it as a deep, pressurized environment where data points are luminous objects floating in a dark navy ether. 

We break the "template" look by utilizing **intentional asymmetry** and **tonal depth**. Layouts should avoid rigid, centered predictability. Use overhanging hero elements, offset typography, and staggered grid placements to create a sense of movement. High-contrast typography scales (jumping from `display-lg` to `label-sm`) create a hierarchical "shock" that guides the eye immediately to the most vital financial metrics.

---

## 2. Colors & Surface Architecture

The palette is rooted in a deep, textured navy, punctuated by high-chroma accents that represent different financial states.

### Surface Hierarchy & The "No-Line" Rule
Traditional UI relies on lines to separate ideas. This system prohibits 1px solid borders for sectioning. Boundaries are defined by the **Surface Layering Principle**:

*   **The Void (Base):** `surface` (#11131E) with a 2% grain texture overlay.
*   **The Foundation:** `surface_container_low` (#191B26) for large background sections.
*   **The Object:** `surface_container` (#1D1F2B) for standard cards.
*   **The Focus:** `surface_container_highest` (#323440) for active or hovered states.

### The Glass & Gradient Rule
To achieve a premium, custom feel, use **Glassmorphism** for all floating UI (modals, navbars, dropdowns). 
*   **Recipe:** `surface_container` at 80% opacity + `backdrop-filter: blur(12px)`.
*   **The Soul:** Use linear gradients for primary actions, transitioning from `primary` (#6FFFDC) to `primary_container` (#00E5BF) at a 135-degree angle.

---

## 3. Typography: The Editorial Voice

We use **Manrope** for its geometric yet approachable skeleton. The hierarchy is designed to feel like a high-end financial magazine.

*   **Display & Headlines:** Use `display-lg` (3.5rem) for total balances. Apply a subtle `text-shadow: 0 0 12px rgba(255,255,255,0.2)` to white text against the dark background to simulate a "neon glow" on high-value numbers.
*   **The Contrast Gap:** Pair `headline-lg` titles with `label-sm` metadata. The extreme difference in scale removes the "generic" feel and adds professional authority.
*   **Functional Text:** `body-md` is the workhorse. Use `on_surface_variant` (#B9CAC3) for secondary descriptions to keep the visual noise low.

---

## 4. Elevation & Depth: Tonal Layering

We move away from Material Design’s standard "shadow-drop" and toward **Ambient Luminescence.**

*   **Layering over Shadowing:** Instead of a shadow, place a `surface_container_highest` card on top of a `surface_dim` background. The shift in hex value provides all the separation needed.
*   **The Ghost Border:** If a container requires a stroke (e.g., in complex data tables), use a "Ghost Border": `outline_variant` (#3B4A45) at 20% opacity. 
*   **Inner Glow:** For hero cards (like a "Current Balance" card), apply an `inner-shadow: 0 1px 1px rgba(255,255,255,0.1)`. This makes the card feel like a physical slab of polished glass.
*   **Ambient Glow:** For floating elements, use a tinted shadow. A "Savings" card should use a 5% opacity `secondary` (#CEBDFF) shadow with a 40px blur, making it look like the card is emitting light onto the surface below.

---

## 5. Components

### Buttons & Inputs
*   **Primary Action:** Pill-shaped (`full` radius) using the Teal gradient. No border. High-contrast `on_primary` (#00382D) text.
*   **Glass Secondary:** `surface_container` at 40% opacity with a 1px "Ghost Border."
*   **Input Fields:** Avoid boxes. Use a bottom-border-only approach or a very subtle `surface_container_lowest` fill with 12px rounded corners. The cursor and label-focus should always use `primary` teal.

### Cards & Lists
*   **The "No-Divider" Rule:** Explicitly forbid horizontal lines between list items. Use **Vertical Negative Space** (Spacing 4 or 6) to separate list entries.
*   **Hero Cards:** 16dp radius. Must feature a "Glow Border"—a subtle 1px stroke using a 50% opacity gradient of the category color (e.g., Coral for Expenses).

### Interaction Elements
*   **Pill Navbar:** A 24dp radius floating bar. It must use the Glassmorphism recipe and stay anchored at the bottom of the viewport with a `20px` margin.
*   **Charts:** Use `primary` to `tertiary` gradients. Every data point should have a "highlight glow" (a 4px blur circle) sitting behind the vertex.

---

## 6. Do’s and Don'ts

### Do
*   **DO** use whitespace as a separator. If you think you need a line, add 16px of space instead.
*   **DO** use "Contextual Glow." If a balance is positive, give the text a faint green outer glow.
*   **DO** lean into asymmetry. Place a large display number on the far left and the supporting label on the far right.

### Don’t
*   **DON'T** use pure black (#000000). It kills the depth of the dark navy "Void."
*   **DON'T** use high-opacity borders. They create "visual friction" that breaks the glass aesthetic.
*   **DON'T** use standard Material elevation shadows. They look muddy on dark navy backgrounds. Use tonal shifts or tinted ambient glows instead.