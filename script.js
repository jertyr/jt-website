// Mode switching functionality
window.setMode = function(mode) {
    const body = document.body;
    const buttons = document.querySelectorAll('.mode-btn');

    console.log('setMode called with:', mode);

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
            console.log('Normal mode activated - Clean blog style');
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
            console.log('Body classes:', body.className);
            break;
    }
};

// Wait for DOM to be ready before running any code
document.addEventListener('DOMContentLoaded', function() {
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

    // Set up mode button event listeners
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

    // Show loading state
    instagramGrid.innerHTML = '<p style="grid-column: 1 / -1; text-align: center; color: #00FF00;">Loading posts...</p>';

    // Directly load fallback posts with thumbnails
    loadFallbackPosts();
}

async function loadFallbackPosts() {
    const posts = [
        { shortcode: 'DTtexVCD3Ai', img: 'https://scontent.cdninstagram.com/v/t51.29350-15/479457697_1104845667995172_2875673467815253888_n.jpg' },
        { shortcode: 'DTtaTuvD8E_', img: 'https://scontent.cdninstagram.com/v/t51.29350-15/479455913_551776831137562_3374619054467091166_n.jpg' },
        { shortcode: 'DTol_-rDmRY', img: 'https://scontent.cdninstagram.com/v/t51.29350-15/479396882_1106993624456949_4695883395775848974_n.jpg' },
        { shortcode: 'DTolioFCadH', img: 'https://scontent.cdninstagram.com/v/t51.29350-15/479486530_1293857121632453_1293932736668738882_n.jpg' },
        { shortcode: 'DToB3i2iS5V', img: 'https://scontent.cdninstagram.com/v/t51.29350-15/479371551_1100849398325952_2894639889990736606_n.jpg' },
        { shortcode: 'DToBkJTicI9', img: 'https://scontent.cdninstagram.com/v/t51.29350-15/479372348_1292894218393802_6034914046664878968_n.jpg' },
        { shortcode: 'DToBUPGCSO6', img: 'https://scontent.cdninstagram.com/v/t51.29350-15/479323815_933026622223927_7815806896577858716_n.jpg' },
        { shortcode: 'DToBN_qib2o', img: 'https://scontent.cdninstagram.com/v/t51.29350-15/479327316_609853804969093_7903866936513698026_n.jpg' },
        { shortcode: 'DToBAWQiXuC', img: 'https://scontent.cdninstagram.com/v/t51.29350-15/479370424_1106669427779764_8699992726858704302_n.jpg' }
    ];

    const instagramGrid = document.querySelector('.instagram-grid');
    instagramGrid.innerHTML = ''; // Clear loading message

    posts.forEach(post => {
        const postUrl = `https://www.instagram.com/p/${post.shortcode}/`;
        const postElement = document.createElement('a');
        postElement.href = postUrl;
        postElement.target = '_blank';
        postElement.className = 'instagram-post';

        // Use actual Instagram CDN URL with fallback
        postElement.innerHTML = `<img src="${post.img}" alt="Instagram post" loading="lazy" onerror="this.style.display='none'; this.parentElement.innerHTML='<div style=\\'width: 100%; height: 100%; background: linear-gradient(135deg, rgba(0, 255, 255, 0.1) 0%, rgba(255, 0, 255, 0.1) 100%); display: flex; align-items: center; justify-content: center; color: #FF00FF; font-size: 48px;\\'>📷</div>';">`;

        instagramGrid.appendChild(postElement);
    });
}
