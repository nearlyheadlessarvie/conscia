# Conscia Enhancement Initiative - Master Documentation Index

**Project Codename**: Duolingo for Financial Discipline  
**Status**: Phases 1-3 Implemented | Conscience Journey Added to MVP Scope | Phase 4+ Planned  
**Timeline**: Original 8-phase roadmap retained for remaining work  
**Last Updated**: 2026-05-11

---

## 📚 Documentation Overview

## 🎭 Story Demo Seed

For a realistic emulator walkthrough across dashboard, budgets, insights, alerts, reflections, recurring items, and pre-purchase context, use the dedicated `story-demo` seed profile.

Local setup:
- Run `dotnet run --project tools/DynamoSetup` after a fresh Docker reset or whenever local Dynamo tables are missing.
- Run `dotnet run --project tools/Seeder -- story-demo` to recreate the curated demo user and its linked product data.
- Re-running the seed is safe for the demo user: it replaces only the `story-demo@example.com` relational slice and the matching user-scoped Dynamo records.
- The story profile includes a premium demo user, 3-month transaction history, recurring schedules with generated occurrences, active notification-bell alerts, weekly insights, budget trends, regret patterns, and enough category/merchant context for pre-purchase assistant checks.

### Current Product Snapshot

- Phases 1-3 are implemented in the current app branch, including dashboard insights, onboarding profiling, transaction-entry redesign, regret memory foundations, and the main shell refresh.
- Add Transaction and Pre-Purchase Assistant now share first-use `Smart location suggestions`, with a later Settings toggle for control.
- Unbudgeted expense categories now create an in-app budget nudge with a direct path back to budget management.
- Recurring expense and income schedules are now supported with weekly, monthly, and yearly cadence, optional end dates, automatic occurrence generation, and reminder alerts.
- Phase 5 is now MVP-scoped as Conscience Journey: a richer but modular gamification layer with XP, levels, weekly quests, badges, and mascot moments.
- Other Phase 4+ roadmap items remain planned work.

All documentation for the Conscia enhancement initiative is organized into 6 comprehensive documents. Start with your role below:

### Quick Start by Role

**👨‍💻 For Developers**
1. Start: [implementation-tasks.md](implementation-tasks.md) for the remaining roadmap
2. Then: [implementation-plan.md](implementation-plan.md) for the long-term vision
3. Then: `docs/superpowers/specs/` and `docs/superpowers/plans/` for the most recently delivered branch work

**🎨 For Product/Design Team**
1. Start: [implementation-plan.md](implementation-plan.md) - Sections 1-3 and 7-10
2. Then: [implementation-tasks.md](implementation-tasks.md) - Phases 4-8
3. Use `docs/superpowers/specs/` for current feature-level decisions and polish notes

**🧪 For QA/Testing**
1. Start: [implementation-tasks.md](implementation-tasks.md) for planned coverage by phase
2. Then: `docs/superpowers/specs/` for current branch behavior changes
3. Use the older snapshot docs below only as historical context

**📊 For Project Management**
1. Start: [README.md](README.md) - roadmap and current product snapshot
2. Then: [implementation-tasks.md](implementation-tasks.md) - remaining roadmap phases
3. Then: [implementation-plan.md](implementation-plan.md) - original 8-phase vision

---

## 📖 Document Directory

### 1. [implementation-plan.md](implementation-plan.md) ⭐ CURRENT LONG-TERM VISION
**Length**: 3,500+ lines | **Read Time**: 45 min | **Updated**: historical baseline from 2026-05-03

**What It Contains**:
- Comprehensive vision for all 8 phases
- Detailed specifications for each feature
- Architecture, database schema, tech stack
- 11 detailed sections:
  1. Enhanced Home Screen with Behavioral Insights
  2. Advanced Feedback Loops
  3. Sharper AI Personality System
  4. Pre-Purchase Input Friction Reduction
  5. Regret Memory System
  6. Floating Action Button Redesign
  7. Overall Positioning as "Financial Discipline Coach"
  8. Technical Architecture
  9. Implementation Phases & Timeline
  10. Success Metrics
  11. Future Enhancements (Post-MVP)

**Best For**: Understanding the complete vision, making strategic decisions, long-term planning

**Key Sections**:
- Section 1: Behavioral insights feature details
- Section 8: Technical architecture and database schema
- Section 9: 8-phase timeline with dependencies
- Section 10: Success metrics and KPIs

---

### 2. [implementation-tasks.md](implementation-tasks.md) ⭐ CURRENT ROADMAP CHECKLIST
**Length**: 2,500+ lines | **Read Time**: 60 min | **Updated**: 2026-05-07

**What It Contains**:
- Detailed task breakdown for all 8 phases
- 85+ specific, actionable tasks
- Dependencies and blockers
- Acceptance criteria
- Frontend, Backend, Testing tasks separated

**Structure**:
```
Phase 1: Dashboard Behavioral Insights (2-3 weeks)
├── Frontend Tasks
├── Backend Tasks
├── Testing & QA
├── Blockers & Dependencies

Phase 2: Friction Reduction (2 weeks)
├── Frontend Tasks
├── Backend Tasks
├── Testing & QA

... (Phases 3-8)

General Tasks (Throughout All Phases)
├── Ongoing Testing
├── Documentation
├── Code Quality
├── DevOps & Infrastructure
└── Analytics & Metrics
```

**Best For**: Breaking down work, assigning tasks, tracking progress, sprint planning

**Key Features**:
- Checklists for each task
- Subtasks with details
- Estimated effort
- Testing requirements
- Dependency information

---

### 3. [phase-1-progress.md](phase-1-progress.md) ⭐ HISTORICAL SNAPSHOT
**Length**: 1,500 lines | **Read Time**: 20 min | **Updated**: historical snapshot from 2026-05-03

**What It Contains**:
- Current implementation status
- What's complete (frontend)
- What's pending (backend)
- Code generation status
- Testing checklist
- Architecture notes
- File structure

**Best For**: Understanding the original Phase 1 checkpoint before later roadmap work landed

**Important Note**:
- This file is no longer the source of truth for current branch status.
- Use [README.md](README.md), [implementation-tasks.md](implementation-tasks.md), and `docs/superpowers/` for the latest feature state.

---

### 4. [QUICK_REFERENCE.md](QUICK_REFERENCE.md) ⭐ HISTORICAL DEVELOPER SNAPSHOT
**Length**: 1,200 lines | **Read Time**: 20 min | **Updated**: historical snapshot from 2026-05-03

**What It Contains**:
- Quick overview of implementation
- File structure and key files
- Data flow diagrams
- UI color system and design system
- Testing strategy
- Next steps priority list
- Tips for backend implementation

**Best For**: Daily reference, onboarding, quick lookups

**Key Sections**:
- Current Status (what's done, what's pending)
- Dashboard Layout (visual guide)
- Data Flow Diagram
- Implementation Details (colors, trends, design)
- Testing Strategy
- Next Steps (priority order)
- Key Files Reference

---

### 5. [SESSION_SUMMARY.md](SESSION_SUMMARY.md) ⭐ HISTORICAL SESSION SUMMARY
**Length**: 2,000 lines | **Read Time**: 30 min | **Updated**: historical snapshot from 2026-05-03

**What It Contains**:
- Complete session summary
- Before/after dashboard transformation
- Technical details
- Impact analysis
- Timeline overview
- Success metrics
- Getting started guide for each role

**Best For**: Project stakeholders, comprehensive overview, impact assessment

**Key Sections**:
- What Was Accomplished
- Documentation Created
- Flutter Code Implemented
- Dashboard Transformation (visual)
- Technical Details
- Impact Analysis
- Timeline Overview
- Success Metrics
- Documentation Structure

---

### 6. [This File - MASTER INDEX](README.md)
**Length**: 500 lines | **Read Time**: 10 min | **Updated**: 2026-05-07

**What It Contains**:
- Navigation guide for all documentation
- Quick start by role
- Document directory with descriptions
- Cross-references between documents
- FAQ and common questions

---

## 🗺️ Navigation Guide

### By Feature/Phase
| Feature | Main Doc | Task Checklist | Progress |
|---------|----------|---|---|
| Dashboard Insights | implementation-plan.md §1 | implementation-tasks.md §1 | Implemented |
| Friction Reduction | implementation-plan.md §4 | implementation-tasks.md §2 | Implemented / evolving |
| Regret Memory | implementation-plan.md §5 | implementation-tasks.md §3 | Implemented / evolving |
| AI Personality | implementation-plan.md §3 | implementation-tasks.md §4 | Planned |
| Conscience Journey Gamification | implementation-plan.md §7.2, §8 | implementation-tasks.md §5 | MVP scope / planned |
| Weekly Digest | implementation-plan.md §2 | implementation-tasks.md §6 | Planned |
| Insights Tab | implementation-plan.md §1,5 | implementation-tasks.md §7 | Planned |
| Positioning | implementation-plan.md §7 | implementation-tasks.md §8 | Planned |

### By Technical Aspect
| Aspect | In Plan | In Tasks | In Progress |
|--------|---------|----------|---|
| Database Schema | §8 | General | phase-1-progress.md |
| API Endpoints | §2 | All phases | phase-1-progress.md |
| Backend Services | §8 | All phases | phase-1-progress.md |
| Frontend Widgets | §1-7 | All phases | phase-1-progress.md |
| State Management | §8 | All phases | QUICK_REFERENCE.md |
| Testing Strategy | None | All phases | QUICK_REFERENCE.md |

### By Timeline
| Time | What | Doc |
|------|------|-----|
| Week 1-3 | Phase 1: Dashboard Insights | phase-1-progress.md |
| Week 4-5 | Phase 2: Friction Reduction | implementation-tasks.md §2 |
| Week 6-8 | Phase 3: Regret Memory | implementation-tasks.md §3 |
| Week 9-10 | Phase 4: AI Personality | implementation-tasks.md §4 |
| Week 11-12 | Phase 5: Conscience Journey Gamification | implementation-tasks.md §5 |
| Week 13-14 | Phase 6: Weekly Digest | implementation-tasks.md §6 |
| Week 15-16 | Phase 7: Insights Tab | implementation-tasks.md §7 |
| Week 17-18 | Phase 8: Positioning | implementation-tasks.md §8 |

---

## 🔗 Cross-References

### From Implementation Plan
- **§1** (Dashboard Insights) → See phase-1-progress.md for current status
- **§8** (Architecture) → See QUICK_REFERENCE.md for data flow diagrams
- **§9** (Timeline) → See implementation-tasks.md for detailed breakdown
- **§10** (Metrics) → See SESSION_SUMMARY.md for impact analysis

### From Implementation Tasks
- **Phase 1** → See phase-1-progress.md for current status
- **Backend Tasks** → See implementation-plan.md §8 for architecture
- **Testing Strategy** → See QUICK_REFERENCE.md for comprehensive test plan
- **All Phases** → See implementation-plan.md for detailed vision

### From Phase 1 Progress
- **Next Steps** → See implementation-tasks.md Phase 1 Backend section
- **Architecture** → See implementation-plan.md §8
- **Testing** → See QUICK_REFERENCE.md Testing Strategy section

### From Quick Reference
- **Implementation Details** → See implementation-plan.md relevant sections
- **Data Flow** → See implementation-plan.md §8 (Architecture)
- **Next Steps** → See implementation-tasks.md Phase 1 Backend section
- **Testing Strategy** → See QUICK_REFERENCE.md or implementation-tasks.md

---

## 📋 Common Questions

### "Where do I start?"
**Answer**: Depends on your role:
- **Developer**: implementation-tasks.md → implementation-plan.md → `docs/superpowers/`
- **Product Manager**: implementation-plan.md (Sections 1-3, 7-10) → implementation-tasks.md
- **QA/Testing**: implementation-tasks.md → `docs/superpowers/specs/`
- **Project Manager**: README.md → implementation-tasks.md → implementation-plan.md

### "What's been completed?"
**Answer**: The current branch has Phases 1-3 substantially implemented, with later phases still planned. See:
- [phase-1-progress.md](phase-1-progress.md) for the original Phase 1 snapshot
- [implementation-tasks.md](implementation-tasks.md) for the remaining roadmap
- the current feature specs/plans in `docs/superpowers/` for recently delivered work such as onboarding profiling and location-aware assistance

### "What's the next step?"
**Answer**: The next roadmap phases are AI Personality, Conscience Journey Gamification, Weekly Digest, Insights Tab, and Positioning. See:
- [implementation-tasks.md](implementation-tasks.md) - Phases 4-8
- [implementation-plan.md](implementation-plan.md) - product vision and sequencing
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - day-to-day implementation notes

### "How long will this take?"
**Answer**: 16-20 weeks total (4-5 months). See:
- [implementation-plan.md](implementation-plan.md) - Section 9 (Timeline)
- [SESSION_SUMMARY.md](SESSION_SUMMARY.md) - Timeline Overview table

### "What are we trying to achieve?"
**Answer**: Transform Conscia into "Duolingo for financial discipline". See:
- [implementation-plan.md](implementation-plan.md) - Section 1-7 (all features)
- [SESSION_SUMMARY.md](SESSION_SUMMARY.md) - Sections "What Was Accomplished" and "Impact Analysis"

### "How does this architecture work?"
**Answer**: See:
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Data Flow Diagram
- [implementation-plan.md](implementation-plan.md) - Section 8 (Architecture)
- [phase-1-progress.md](phase-1-progress.md) - Architecture Notes section

### "What files were created?"
**Answer**: See:
- [SESSION_SUMMARY.md](SESSION_SUMMARY.md) - "Files Created/Modified Summary" section
- [phase-1-progress.md](phase-1-progress.md) - "Files Modified/Created" section
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - "Implementation Details" section

### "How do I run tests?"
**Answer**: See:
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - "Testing Strategy" section
- [implementation-tasks.md](implementation-tasks.md) - Phase 1 "Testing & QA" section

### "What's the color system?"
**Answer**: See:
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - "FinancialMood Colors" and "Trend Arrows" sections
- [implementation-plan.md](implementation-plan.md) - Section 1.1-1.3 (feature details)

### "When does Phase 4 start?"
**Answer**: Phases 1-3 are already implemented on the current branch. The next roadmap milestone is Phase 4: AI Personality. See:
- [implementation-tasks.md](implementation-tasks.md) - Phase 4 section
- [implementation-plan.md](implementation-plan.md) - Section 9 (Timeline)

---

## 📊 Documentation Statistics

| Document | Lines | Words | Read Time | Key Info |
|----------|-------|-------|-----------|----------|
| implementation-plan.md | 3,500+ | 18,000+ | 45 min | Complete vision |
| implementation-tasks.md | 2,500+ | 14,000+ | 60 min | Task breakdown |
| phase-1-progress.md | 1,500 | 8,000 | 20 min | Current status |
| QUICK_REFERENCE.md | 1,200 | 6,500 | 20 min | Developer guide |
| SESSION_SUMMARY.md | 2,000 | 11,000 | 30 min | Comprehensive summary |
| This Index | 500 | 2,500 | 10 min | Navigation guide |
| **TOTAL** | **11,200+** | **60,000+** | **2.5 hours** | Complete project docs |

---

## 🔄 Document Maintenance

### How to Keep These Updated
1. **Current roadmap state**: Update [README.md](README.md) and [implementation-tasks.md](implementation-tasks.md)
2. **Feature-level decisions**: Add or revise docs in `docs/superpowers/specs/`
3. **Execution details**: Add or revise docs in `docs/superpowers/plans/`
4. **Historical docs**: Only refresh `phase-1-progress.md`, `QUICK_REFERENCE.md`, or `SESSION_SUMMARY.md` if you are intentionally preserving or correcting the older snapshot

### Versioning
- All documents are living documents (constantly updated)
- Last updated: 2026-05-07
- Next update: After the next roadmap phase begins or the documented roadmap changes materially

---

## 📞 Getting Help

### For Understanding the Vision
→ Read [implementation-plan.md](implementation-plan.md) Sections 1-7

### For Breaking Down Work
→ Use [implementation-tasks.md](implementation-tasks.md) as checklist

### For Current Status
→ Check [README.md](README.md), [implementation-tasks.md](implementation-tasks.md), and `docs/superpowers/`

### For Quick Answers
→ See FAQ section above

### For Next Steps
→ Read [QUICK_REFERENCE.md](QUICK_REFERENCE.md) "Next Steps" section

---

## 🚀 Quick Navigation Links

**Current Branch Work**:
- Roadmap status: [implementation-tasks.md](implementation-tasks.md)
- Long-term vision: [implementation-plan.md](implementation-plan.md)
- Recent feature specs: `docs/superpowers/specs/`
- Recent implementation plans: `docs/superpowers/plans/`

**All Phases Overview**:
- Timeline: [implementation-plan.md §9](implementation-plan.md#9-implementation-phases--timeline)
- Task List: [implementation-tasks.md](implementation-tasks.md)
- Summary: [SESSION_SUMMARY.md](SESSION_SUMMARY.md)

**Technical Details**:
- Architecture: [implementation-plan.md §8](implementation-plan.md#8-technical-architecture)
- Data Flow: [QUICK_REFERENCE.md](QUICK_REFERENCE.md#-data-flow)
- Code Files: [phase-1-progress.md](phase-1-progress.md#files-modifiedcreated)

---

**Last Updated**: 2026-05-11  
**Status**: Phases 1-3 Implemented  
**Next Milestone**: Phase 4 AI Personality, followed by MVP Conscience Journey  
**Total Project**: Original 8-phase roadmap remains the planning baseline
