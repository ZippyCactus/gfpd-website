// /api/getEvents.js

const ical = require('node-ical');

// This is the main serverless function handler.
// Vercel automatically knows how to run this.
module.exports = async (req, res) => {
    // Get the secret calendar URL from an environment variable.
    const calendarUrl = process.env.OUTLOOK_CALENDAR_URL;

    if (!calendarUrl) {
        // If the URL isn't set up, send an error.
        return res.status(500).json({ error: 'Server configuration error: Calendar URL not found.' });
    }

    try {
        // Fetch and parse the calendar data from the URL.
        const events = await ical.async.fromURL(calendarUrl);
        const formattedEvents = [];

        // Loop through the parsed calendar events.
        for (const event of Object.values(events)) {
            // We only care about single events, not recurring ones for now.
            if (event.type === 'VEVENT' && event.start) {
                
                // Format the start and end times into a readable string.
                const timeOptions = { hour: 'numeric', minute: '2-digit', hour12: true };
                const startTime = new Date(event.start).toLocaleTimeString('en-US', timeOptions).replace(' ', '');
                const endTime = event.end ? new Date(event.end).toLocaleTimeString('en-US', timeOptions).replace(' ', '') : '';

                formattedEvents.push({
                    title: event.summary || 'No Title',
                    date: new Date(event.start).toISOString().split('T')[0], // YYYY-MM-DD
                    time: event.end ? `${startTime} - ${endTime}` : startTime,
                    location: event.location || 'No Location Provided',
                    description: event.description || 'No Description Provided.',
                });
            }
        }

        // Send the formatted events back to the browser as JSON.
        res.status(200).json(formattedEvents);

    } catch (error) {
        console.error('Failed to fetch or parse calendar data:', error);
        res.status(500).json({ error: 'Failed to retrieve calendar events.' });
    }
};