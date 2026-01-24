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
});
