# Unpoly Usage Rules

Guidelines for AI assistants when working with ex_unpoly and Unpoly.

## Unpoly Attributes

1. **Attribute Naming**
   - All Unpoly attributes use the `up-` prefix (e.g., `up-target`, `up-layer`, `up-follow`)
   - Always use lowercase with hyphens for attribute names
   - Never use camelCase or snake_case for Unpoly attributes

2. **Phoenix Component Configuration**
   - When using Phoenix Components (HEEx), configure global prefixes to allow `up-` attributes
   - Add `global_prefixes: ~w(up-)` to the `Phoenix.Component` configuration
   - This is required in the `html/0` function in your web module

3. **Common Attributes**
   - `up-target`: Specifies which fragment to update
   - `up-layer`: Opens content in a layer (overlay, modal, drawer)
   - `up-follow`: Makes an element follow links with Unpoly
   - `up-validate`: Validates a form field on change
   - `up-submit`: Makes a form submit via AJAX
   - `up-poll`: Polls a fragment for updates
   - `up-fragment`: Marks an element as a fragment

## Server-Side Response Headers

1. **Unpoly Request Detection**
   - Check `conn.assigns.unpoly?` to detect Unpoly requests
   - The plug automatically parses Unpoly headers and assigns them to conn
   - Access Unpoly metadata via `conn.assigns.unpoly`

2. **Response Headers**
   - Use `Unpoly.context/2` to set context data for the frontend
   - Use `Unpoly.target/2` to override the target selector
   - Use `Unpoly.layer/2` to configure layer behavior
   - Use `Unpoly.events/2` to emit events to the frontend
   - These functions return an updated conn with appropriate headers

3. **Fragment Rendering**
   - Only render the requested fragment for Unpoly requests
   - Check `conn.assigns.unpoly.target` to determine what fragment is requested
   - Render full pages for non-Unpoly requests
   - Use conditional rendering based on `conn.assigns.unpoly?`

## Layer Handling

1. **Opening Layers**
   - Use `up-layer="new"` to open content in a new layer
   - Specify layer mode with values: `overlay`, `modal`, `drawer`, `popup`, `cover`
   - Configure layer options with `up-size`, `up-class`, `up-dismissable`

2. **Closing Layers**
   - Return `X-Up-Accept-Layer` header to accept and close a layer
   - Return `X-Up-Dismiss-Layer` header to dismiss and close a layer
   - Set layer values with `Unpoly.accept_layer/2` or `Unpoly.dismiss_layer/2`

3. **Layer Events**
   - Listen for layer lifecycle events: `up:layer:open`, `up:layer:opened`, `up:layer:dismissed`
   - Handle layer acceptance/dismissal on the server side
   - Pass data back to the parent layer via accept/dismiss values

## Navigation and History

1. **URL Updates**
   - Use `up-history="true"` to update the browser URL
   - Set `up-history="false"` to prevent URL updates
   - Return `X-Up-Location` header to set the URL from the server
   - Use `Unpoly.location/2` to set the location header

2. **Titles**
   - Return `X-Up-Title` header to set the page title
   - Use `Unpoly.title/2` to set the title header
   - Always provide descriptive titles for better UX

## Form Handling

1. **Form Submission**
   - Use `up-submit` attribute on forms for AJAX submission
   - Specify `up-target` to define where the response should be rendered
   - Use `up-validate` on inputs for server-side validation

2. **Validation Responses**
   - Return the form with errors for failed validation
   - Return the success fragment for successful submissions
   - Use proper HTTP status codes (422 for validation errors, 200 for success)

3. **Form State**
   - Preserve form state across validation requests
   - Use `up-keep` to preserve certain elements during updates
   - Handle file uploads properly with multipart forms

## Testing

1. **Request Headers**
   - Set `X-Up-Version` header to simulate Unpoly requests
   - Set `X-Up-Target` header to specify the requested fragment
   - Set `X-Up-Mode` header to indicate layer mode

2. **Response Assertions**
   - Assert on Unpoly response headers (e.g., `X-Up-Target`, `X-Up-Events`)
   - Verify fragment-only responses for Unpoly requests
   - Test both Unpoly and full-page request scenarios

3. **Integration Tests**
   - Test layer opening and closing
   - Verify form validation and submission
   - Test navigation and history updates

## Performance

1. **Fragment Optimization**
   - Only render the minimal HTML needed for the requested fragment
   - Avoid rendering the full layout for Unpoly requests
   - Use conditional rendering to optimize response size

2. **Preloading**
   - Use `up-preload` on links to preload content on hover
   - Implement caching strategies for frequently accessed fragments
   - Consider using `up-cache` to control caching behavior

3. **Polling**
   - Use `up-poll` judiciously to avoid excessive server load
   - Set appropriate polling intervals
   - Implement conditional polling based on user activity

## Common Patterns

1. **Navigation Menu**
   - Mark the current page with `up-current` attributes
   - Use `up-nav` on navigation containers for automatic current marking
   - Implement smooth transitions between pages

2. **Modal Workflows**
   - Open forms in layers for focused interactions
   - Return accept/dismiss responses to close layers
   - Pass data back to the parent layer

3. **Inline Editing**
   - Use `up-validate` for real-time validation
   - Update specific fragments without full page reloads
   - Provide immediate feedback to users

## Error Handling

1. **Server Errors**
   - Return appropriate HTTP status codes
   - Render error fragments for Unpoly requests
   - Provide user-friendly error messages

2. **Network Errors**
   - Implement proper error handling on the frontend
   - Use `up:fragment:loaded` event to handle load errors
   - Provide fallback behavior for failed requests

3. **Validation Errors**
   - Return 422 status for validation errors
   - Render the form with error messages
   - Highlight invalid fields clearly
