// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Mode switching functionality
window.setMode = function(mode) {
    const body = document.body;
    const buttons = document.querySelectorAll('.mode-btn');

    // Remove all mode classes
    body.classList.remove('sim-city-mode', 'ultra-chaos');

    // Remove active class from all buttons
    buttons.forEach(btn => btn.classList.remove('active'));

    // Find and activate the clicked button
    const activeButton = document.querySelector(`[data-mode="${mode}"]`);
    if (activeButton) {
        activeButton.classList.add('active');
    }

    switch(mode) {
        case 'normal':
            body.classList.add('sim-city-mode');
            console.log('Normal mode activated - Classic Sim City 2000 aesthetic');
            console.log('Body classes:', body.className);
            break;
        case 'nutters':
            // Default cyberpunk chaos - no class needed
            console.log('Nutters mode - Cyberpunk construction chaos');
            console.log('Body classes:', body.className);
            break;
        case 'mayhem':
            body.classList.add('ultra-chaos');
            console.log('🔥🔥🔥 MAYHEM MODE ACTIVATED 🔥🔥🔥');
            console.log('Warning: Maximum chaos levels detected!');
            console.log('Everything is spinning and rainbow now!');
            console.log('Comic Sans has been deployed!');
            console.log('Body classes:', body.className);
            break;
    }
};

// Set up button event listeners
document.addEventListener('DOMContentLoaded', function() {
    const modeButtons = document.querySelectorAll('.mode-btn');

    console.log('Found ' + modeButtons.length + ' mode buttons');

    modeButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            const mode = this.getAttribute('data-mode');
            console.log('Button clicked: ' + mode);
            window.setMode(mode);
        });
    });

    // Set initial mode to normal (clean blog style)
    window.setMode('normal');

    // Load Instagram posts
    loadInstagramPosts();
});

// Instagram posts loader
async function loadInstagramPosts() {
    const instagramGrid = document.querySelector('.instagram-grid');
    if (!instagramGrid) return;

    const username = 'rem.guide';

    // Show loading state
    instagramGrid.innerHTML = '<p style="grid-column: 1 / -1; text-align: center; color: #00FF00;">Loading posts...</p>';

    // Try multiple methods to fetch Instagram posts
    try {
        // Method 1: Try Instagram's public JSON endpoint
        let response = await fetch(`https://www.instagram.com/${username}/?__a=1&__d=dis`);

        if (!response.ok) {
            // Method 2: Try the web profile info endpoint
            response = await fetch(`https://www.instagram.com/api/v1/users/web_profile_info/?username=${username}`, {
                headers: {
                    'x-ig-app-id': '936619743392459'
                }
            });
        }

        if (response.ok) {
            const data = await response.json();
            let posts = null;

            // Parse different response formats
            if (data.graphql?.user?.edge_owner_to_timeline_media) {
                posts = data.graphql.user.edge_owner_to_timeline_media.edges;
            } else if (data.data?.user?.edge_owner_to_timeline_media) {
                posts = data.data.user.edge_owner_to_timeline_media.edges;
            }

            if (posts && posts.length > 0) {
                instagramGrid.innerHTML = ''; // Clear loading message
                posts.slice(0, 9).forEach(post => {
                    const node = post.node;
                    const postUrl = `https://www.instagram.com/p/${node.shortcode}/`;
                    const thumbnailUrl = node.thumbnail_src || node.display_url;

                    const postElement = document.createElement('a');
                    postElement.href = postUrl;
                    postElement.target = '_blank';
                    postElement.className = 'instagram-post';
                    postElement.innerHTML = `<img src="${thumbnailUrl}" alt="Instagram post" loading="lazy">`;

                    instagramGrid.appendChild(postElement);
                });
                return;
            }
        }

        throw new Error('Failed to fetch Instagram posts');
    } catch (error) {
        console.log('Instagram API not accessible:', error);
        loadFallbackPosts();
    }
}

function loadFallbackPosts() {
    // Fallback: manually specified post shortcodes
    const postShortcodes = [
        'DTtexVCD3Ai',
        'DTtaTuvD8E_',
        'DTol_-rDmRY',
        'DTolioFCadH',
        'DToB3i2iS5V',
        'DToBkJTicI9',
        'DToBUPGCSO6',
        'DToBN_qib2o',
        'DToBAWQiXuC'
    ];

    const instagramGrid = document.querySelector('.instagram-grid');

    if (postShortcodes.length === 0) {
        instagramGrid.innerHTML = '<p style="grid-column: 1 / -1; text-align: center; color: #00FF00;">Instagram posts coming soon...</p>';
        return;
    }

    postShortcodes.forEach(shortcode => {
        const postUrl = `https://www.instagram.com/p/${shortcode}/`;
        const postElement = document.createElement('a');
        postElement.href = postUrl;
        postElement.target = '_blank';
        postElement.className = 'instagram-post';
        postElement.innerHTML = `<img src="https://www.instagram.com/p/${shortcode}/media/?size=m" alt="Instagram post" loading="lazy" onerror="this.src='data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 width=%22400%22 height=%22400%22><rect fill=%22%23f0f0f0%22 width=%22400%22 height=%22400%22/><text x=%2250%25%22 y=%2250%25%22 text-anchor=%22middle%22 dy=%22.3em%22 fill=%22%23999%22 font-family=%22sans-serif%22>📷</text></svg>'">`;

        instagramGrid.appendChild(postElement);
    });
});
