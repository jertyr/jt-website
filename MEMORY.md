# Repository Memory: jt-website

## Project Overview
Personal portfolio website for Jerry Tyrrell, Project Manager at Dexter Builders in Ann Arbor, MI. The site showcases writing, projects, and professional work in residential construction and remodeling.

## Repository Structure
- `index.html` - Main portfolio page with sections for Writing, Projects, Instagram, and Contact
- `styles.css` - Complete styling including responsive design and theme modes
- `script.js` - Interactive features including Normal/Nutters/Mayhem mode switching
- `robots.txt` - Search engine configuration (noindex)

## Recent Updates (February 2026)

### Instagram Integration Evolution
- **PR #27**: Simplified Instagram integration by removing grid layout and replacing with simple link to @rem.guide profile
- **PR #26**: Added Instagram thumbnail URLs for posts
- **PR #25**: Fixed JavaScript syntax error in loadFallbackPosts function
- **PR #24**: Added 9 Instagram posts to fallback array, reduced spacing, and added Instagram auto-loader
- **PR #23**: Moved Instagram section below Projects section
- **PR #22**: Added Instagram section with 3x3 grid layout

### Content & LinkedIn Posts
- **PR #22**: Added LinkedIn post "Construction's Competitive Advantage in an AI-Driven World" (Jan 18, 2026)
- Pattern: LinkedIn posts are added to the Writing section with date, title, summary, and link

### UI Improvements
- **PR #20**: Added horizontal dividers above Projects and Contact sections
- **PR #26**: Refactored script.js to fix mode switching issues between Normal, Nutters, and Mayhem modes

## Writing Section Pattern
Each LinkedIn post follows this structure:
```html
<div class="post-tile">
    <div class="post-meta">[Date]</div>
    <h3><a href="[LinkedIn URL]" target="_blank">[Title]</a></h3>
    <p>[Summary] <a href="[LinkedIn URL]" target="_blank" class="read-more">Read more →</a></p>
</div>
<div class="post-divider"></div>
```

## Current LinkedIn Posts (Chronological Order)
1. Jan 18, 2026 - Construction's Competitive Advantage in an AI-Driven World
2. Jan 1, 2026 - Ann Arbor Permit Data: Homeowners Spend Big on Fewer Projects
3. Dec 24, 2025 - Making Ann Arbor's Bryant Neighborhood a Model for Sustainability
4. Dec 18, 2025 - Custom Library Design Collaboration
5. Dec 14, 2024 - Winter Snow Reveals Home Insulation Quality
6. Oct 12, 2025 - Q3 2025 Ann Arbor Permit Data Analysis

## Key Projects
- **remodelers.guide**: Curated repository of construction notes and articles
- **TradesUP Chelsea**: Initiative to bring trades education to Chelsea, Michigan

## Development Branches
Development work happens on feature branches prefixed with `claude/` following the pattern: `claude/[description]-[sessionId]`

## Contact Information
- Email: jtyrrell@dexterbuilders.com
- LinkedIn: linkedin.com/in/jerrytyrrell
- Instagram: @rem.guide

## Notes for Future Updates
- LinkedIn posts should be added in chronological order (newest first) in the Writing section
- Each post needs a date, title, summary, and link
- Maintain consistent formatting with existing posts
- Include post dividers between posts
- Instagram integration has been simplified to a single link (avoid complex grid layouts)
