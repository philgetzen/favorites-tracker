# Product Requirements Document: Modular Favorites Tracker

## Introduction/Overview

The Modular Favorites Tracker is an iOS native application designed for enthusiasts who want to comprehensively track their favorite items across multiple hobbies and interests. The app provides a flexible template system that allows users to create custom trackers for any hobby while leveraging shared core components. Users can track everything from coffee beans and brewing methods to beard oils and favorite shops, with each tracker offering specialized fields relevant to that particular interest.

The app solves the problem of scattered information across multiple apps and notebooks by providing a unified, customizable platform for tracking all favorites in one place. It features a community-driven template repository where users can share and discover tracking templates for various hobbies.

## Goals

1. **User Engagement**: Achieve 60% 30-day retention rate and 40% 60-day retention rate
2. **Template Ecosystem**: Build a library of 100+ community templates within 6 months
3. **Premium Conversion**: Achieve 15% freemium to premium conversion rate
4. **Active Usage**: Users actively maintain at least 2 trackers with 10+ items each
5. **Community Growth**: 50+ new templates created monthly by users after launch

## User Stories

1. **As a coffee enthusiast**, I want to track my favorite coffee beans with origin, roast level, tasting notes, and brewing methods so that I can remember which ones I enjoyed and how to best prepare them.

2. **As a grooming enthusiast**, I want to track beard oils with their ingredients, scent profiles, and effects so that I can find the perfect combination for my needs.

3. **As a hobby collector**, I want to discover templates created by other enthusiasts so that I don't have to start from scratch when tracking a new interest.

4. **As a location-conscious user**, I want to map where I bought items or visited shops so that I can easily return to my favorite places.

5. **As a premium user**, I want to track unlimited hobbies and export my data so that I have full control over my collections.

6. **As a template creator**, I want to share my tracking templates with the community and see how many people use them.

7. **As a template designer**, I want to access all the same components used in official templates so that I can create professional-looking trackers without starting from scratch.

8. **As a custom component creator**, I want to build specialized input fields and display widgets so that I can capture hobby-specific data that isn't covered by standard components.

## Functional Requirements

### Core Features (All Trackers)

1. **Item Management**
   - Add new items with customizable fields
   - Edit existing items
   - Delete items with confirmation
   - Duplicate items for quick entry

2. **Rating System**
   - 1-5 star rating system
   - Optional half-star ratings
   - Visual rating display in list views

3. **Photo Management**
   - Add multiple photos per item
   - Photo gallery view with zoom
   - Photo captions and dates
   - Camera integration and photo library access

4. **Notes & Descriptions**
   - Rich text notes with formatting
   - Quick note templates
   - Note history tracking

5. **Organization**
   - Tags and categories
   - Custom sorting options
   - Advanced filtering
   - Search across all fields
   - Folder/collection organization

6. **Data Tracking**
   - Date added/modified
   - Last used/accessed date
   - Purchase date and price
   - Availability status

### Template System

7. **Template Management**
   - Browse template repository
   - Search templates by category/keyword
   - Preview template fields before using
   - One-tap template installation

8. **Template Creation**
   - Visual template builder
   - Field type selection (text, number, date, location, etc.)
   - Field validation rules
   - Template preview mode

9. **Community Features**
   - Upload templates to repository
   - Rate and review templates
   - See usage statistics
   - Report inappropriate templates

### Template Creator Flow

10. **Visual Template Builder Interface**
    - Drag-and-drop canvas for component arrangement
    - Real-time preview panel (iPhone/iPad views)
    - Component property inspector
    - Grid/snap-to alignment tools
    - Undo/redo with version history
    - Template metadata editor (name, description, category, icon)

11. **Component Library**
    - **Core Building Blocks**
      - Text input (single/multi-line)
      - Number input (integer/decimal)
      - Date/time pickers
      - Toggle switches
      - Segmented controls
      - Sliders (continuous/stepped)
      - Rating components
      - Photo gallery
      - Location picker
      - Tags/labels
      - Color picker
      - URL input
      - Email/phone inputs
    - **Specialized Components** (from existing templates)
      - Tasting notes wheel
      - Roast level selector
      - Origin country/region picker
      - Brew method selector
      - Ingredient combination builder
      - Concentration calculator
      - Scent profile builder
      - Business hours selector
      - Social media links
      - Ambiance rating matrix
    - **Layout Components**
      - Section headers
      - Grouped containers
      - Tabs/accordion
      - Card layouts
      - List layouts

12. **Custom Component Creator**
    - Component type selector (input, display, composite)
    - Visual property editor
    - Validation rule builder
    - Custom logic editor (SwiftUI-like syntax)
    - Component preview/testing
    - Save to personal library
    - Share with community option

13. **Template Configuration**
    - Field requirements (required/optional)
    - Default values
    - Placeholder text
    - Help text/tooltips
    - Conditional visibility rules
    - Calculated fields formulas
    - Data relationships between fields
    - Import/export field mappings

14. **Template Testing & Preview**
    - Test mode with sample data
    - Device preview (iPhone/iPad)
    - Accessibility checker
    - Performance analyzer
    - Field validation testing
    - Export format preview

15. **Publishing Workflow**
    - Template validation checks
    - Screenshot generator
    - Category selection
    - Keywords/tags
    - Usage instructions editor
    - Version control
    - Update notifications to users
    - Fork/derivative tracking

### Specialized Components

16. **Coffee Tracker**
    - Origin country/region picker
    - Roast level selector
    - Tasting notes wheel
    - Brew method combinations
    - Grind size recommendations
    - Water temperature tracking
    - Brew time logging

17. **Beard Oil Tracker**
    - Carrier oil selector
    - Essential oil combinations
    - Concentration calculator
    - Scent profile builder
    - Skin reaction notes
    - Homemade recipe storage

18. **Location-Based Trackers**
    - Shop hours display
    - Contact information
    - Website/social links
    - Ambiance ratings
    - Specialty items
    - Visit history

### Map Functionality

19. **Map Features**
    - Pin locations for items/shops
    - Cluster view for multiple locations
    - Filter map by tracker type
    - Get directions integration
    - Save favorite locations
    - Location-based reminders

### Data Management

20. **Backup & Sync**
    - Automatic iCloud backup
    - Manual backup triggers
    - Restore from backup
    - Sync across devices

21. **Sharing**
    - Share individual items
    - Share entire collections
    - Export formats (PDF, CSV, JSON)
    - Social media integration

22. **Import/Export**
    - Import from CSV
    - Export with photos
    - Custom export templates

### Premium Features

23. **Unlimited Trackers** (Free: 2 trackers)
24. **Advanced Analytics**
    - Usage patterns
    - Spending analysis
    - Rating trends
    - Custom reports

25. **Themes & Customization**
    - Color theme selector
    - Custom app icons
    - Widget customization

26. **Enhanced Export**
    - Custom PDF layouts
    - Batch operations
    - API access

### Monetization Model

27. **Subscription Tiers**
    - **Free Tier**:
      - 2 trackers maximum
      - 5 photos per item
      - Basic templates only
      - Standard export formats
    - **Premium Tier ($2.99/month)**:
      - Unlimited trackers
      - 10 photos per item
      - All templates access
      - Advanced analytics
      - Premium export options
      - Custom themes
      - Priority support

28. **Template Marketplace**
    - **For Creators**:
      - Set templates as free or premium
      - Price range: $0.99 - $9.99
      - 70% revenue share
      - Real-time sales analytics
      - Payout via Stripe Connect
    - **For Users**:
      - One-time purchase per template
      - Family sharing support
      - Refund window (24 hours)
      - Preview before purchase

29. **Component Marketplace**
    - **Individual Components**: $0.99 - $4.99
    - **Component Packs**: $2.99 - $14.99
    - Same 70/30 revenue split
    - Dependency management
    - Automatic updates

### Additional Core Components

30. **Favorites System**
    - Quick access favorites
    - Favorite folders
    - Smart favorites (auto-updated)

31. **Comparison Tools**
    - Side-by-side comparison
    - Comparison history
    - Share comparisons

32. **History Tracking**
    - Price history graphs
    - Availability tracking
    - Change notifications

33. **Notifications**
    - Restock alerts
    - Price drop notifications
    - Location-based reminders
    - Review reminders

34. **Quick Actions**
    - 3D Touch/Haptic Touch menus
    - Keyboard shortcuts (iPad)
    - Siri Shortcuts integration

35. **Widgets**
    - Home screen widgets
    - Lock screen widgets
    - Interactive widgets

36. **Scanning**
    - Barcode scanner
    - QR code support
    - OCR for text capture

37. **Voice Features**
    - Voice note attachments
    - Voice-to-text input
    - Siri integration

38. **Template Builder**
    - Drag-and-drop field builder
    - Conditional fields
    - Calculated fields
    - Field templates library

### Moderator Dashboard (Web-based)

39. **Content Moderation Interface**
    - Queue of flagged templates/components for review
    - Automated NSFW detection alerts
    - Quick approve/reject actions
    - Bulk moderation tools
    - Content preview with all fields

40. **Reporting & Analytics**
    - Daily/weekly moderation statistics
    - Top reported content categories
    - Creator violation tracking
    - Response time metrics
    - Community health indicators

41. **Moderation Tools**
    - Template/component suspension
    - Creator warnings and bans
    - Content edit suggestions
    - Communication with creators
    - Appeal management system

42. **Automated Filters**
    - NSFW image detection
    - Inappropriate text detection
    - Copyright/trademark scanning
    - Spam detection
    - Configurable sensitivity levels

## Non-Goals (Out of Scope)

1. **Social Network Features**: No user profiles, following, or social feeds
2. **E-commerce Integration**: No direct purchasing or price comparison
3. **Professional Inventory Management**: Not designed for business use
4. **Real-time Collaboration**: No simultaneous multi-user editing
5. **Android Version**: iOS exclusive for initial release
6. **Web Version**: Native app only
7. **AI Recommendations**: No ML-based suggestions in v1
8. **Third-party App Integration**: No direct integration with other tracking apps

## Design Considerations

- **Design Philosophy**: Minimalist and clean with strategic pops of color
- **iOS 26 Compliance**: Strict adherence to latest iOS design guidelines
- **Accessibility**: Full VoiceOver support, Dynamic Type, color blind modes
- **Performance**: Smooth 60fps scrolling, instant search, quick photo loading
- **Animations**: Subtle, purposeful animations that enhance usability
- **Dark Mode**: Full dark mode support with OLED optimization
- **iPad Optimization**: Multi-column layouts, keyboard navigation, drag-and-drop

## Technical Considerations

- **Platform**: iOS 26 minimum, Universal (iPhone + iPad)
- **Architecture**: SwiftUI with Clean Architecture principles
- **Database**: Core Data with CloudKit sync
- **Offline-First**: Full functionality offline with background sync
- **Image Storage**: Efficient image caching and compression
- **Security**: Biometric authentication, encrypted backups
- **Performance**: Lazy loading, virtualized lists, background processing
- **Size**: Target app size under 50MB (excluding user data)

### Component Architecture

- **Component Framework**: SwiftUI-based modular component system
- **Component Registry**: Central registry for all available components
- **Component Protocols**: Standardized interfaces for input, display, and composite components
- **Component Packaging**: JSON-based component definitions with SwiftUI rendering
- **Custom Component Runtime**: Safe execution environment for user-created components
- **Component Versioning**: Backward compatibility for template components
- **Component Performance**: Lazy loading and caching of component definitions
- **Component Security**: Sandboxed execution, no arbitrary code execution

### Database Optimization & Cost Management

- **Data Structure Efficiency**:
  - Normalized database schema to minimize redundancy
  - JSON fields for dynamic template data
  - Efficient indexing on frequently queried fields
  - Separate hot/cold storage for active vs archived data

- **Image Storage Optimization**:
  - Automatic image compression (WebP format)
  - Progressive quality levels (thumbnail, medium, full)
  - CDN integration for global image delivery
  - Lazy loading and caching strategies
  - Automatic cleanup of orphaned images

- **Query Optimization**:
  - Database query caching with Redis
  - Pagination for large datasets
  - Background processing for analytics
  - Connection pooling for scalability

- **Cost Control Measures**:
  - Tiered storage (SSD for active, HDD for archived)
  - Automated data archiving after 1 year of inactivity
  - Photo storage limits (5 free, 10 premium)
  - Template size limits (100KB max)
  - Rate limiting for API calls

- **Monitoring & Analytics**:
  - Real-time cost monitoring dashboard
  - Usage patterns analysis
  - Performance metrics tracking
  - Automated alerts for cost thresholds

## Success Metrics

1. **Active Users**: Daily/Monthly active user ratio > 40%
2. **Premium Conversion**: 15% of users upgrade within 30 days
3. **Template Creation**: 50+ new templates monthly
4. **User Retention**: 60% 30-day, 40% 60-day, 25% 90-day
5. **App Store Rating**: Maintain 4.5+ star rating
6. **Crash Rate**: Less than 0.5% crash-free sessions
7. **Template Usage**: Average user tries 3+ templates
8. **Data Volume**: Average user tracks 50+ items across all trackers

## Key Decisions

1. **Template Moderation**: Automated filtering with manual override capability
   - Automatic NSFW detection and filtering
   - Moderator dashboard for manual review (web-based)
   - Community reporting system for inappropriate content

2. **Pricing Strategy**: Subscription model at $2.99/month
   - Monthly recurring subscription
   - Free tier: 2 trackers with limited features
   - Premium tier: Unlimited trackers with all features

3. **Template Licensing**: Premium template marketplace with revenue sharing
   - Creators can offer templates as free or premium
   - 70/30 revenue split (creator/platform)
   - In-app purchase system for premium templates
   - Creator analytics dashboard

4. **Data Limits**: 
   - Free users: 5 photos per item
   - Premium users: 10 photos per item
   - Cloud storage optimization for cost management

5. **Offline Maps**: Online-only for initial release
   - Requires internet connection for map features
   - Consider offline capability for future releases

6. **Template Updates**: User-controlled update system
   - Notification when template updates available
   - Option to accept or decline updates
   - Update history in template settings panel
   - Ability to revert to previous versions

7. **Multi-language Support**: English-only at launch
   - Focus on core functionality first
   - Internationalization framework built-in for future expansion

8. **Beta Program**: Dual approach
   - TestFlight beta for early adopters
   - Phased rollout for general release
   - Feedback collection system integrated

9. **Custom Component Security**: Comprehensive validation system
   - Sandboxed execution environment
   - No external API calls allowed
   - Limited to UI rendering and data validation
   - No file system or network access
   - Maximum 5-second execution time per component
   - Memory usage limits (10MB per component)
   - Code review for components with high usage

10. **Component Marketplace**: Separate from template marketplace
    - Individual components can be shared/sold
    - Component bundles/packs available
    - Same 70/30 revenue split as templates
    - Version control and dependency management

11. **Component Complexity Limits**: 
    - Maximum 50 fields per template
    - Maximum 10 custom components per template
    - Maximum 5 levels of nesting for composite components
    - Maximum 100KB per template definition

## Initial Template Library

### Launch Templates
1. **Coffee** (beans, brew methods, shops)
2. **Beard Care** (oils, balms, grooming tools)
3. **Wine/Beer/Spirits**
4. **Books/Movies/Music**
5. **Restaurants**
6. **Hiking Trails/Outdoor Spots**
7. **Skincare Products & Routines**
8. **Workout Programs & Exercises**
9. **Recipe Collections**
10. **Travel Destinations & Experiences**

### Phase 2 Templates
11. **Art Supplies & Techniques**
12. **Plant Care & Garden Tracking**
13. **Collectibles** (coins, stamps, cards)
14. **Home Improvement Projects**
15. **Pet Care Products & Vets**