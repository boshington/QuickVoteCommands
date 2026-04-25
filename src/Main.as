[Setting name="Show quick vote window" category="Window"]
bool showWindow = true;

[Setting name="Window X" category="Window" hidden]
float windowX = 40.0f;

[Setting name="Window Y" category="Window" hidden]
float windowY = 160.0f;

[Setting name="Window width" category="Window" hidden]
float windowWidth = 240.0f;

[Setting name="Window height" category="Window" hidden]
float windowHeight = 86.0f;

const float minbuttonSize = 28.0f;
const float buttonSpacing = 4.0f;
const int buttonCount = 4.0f; // Float for calcs later is easier

// For rate limiting votes. Trackmania crashes if you spam votes for some reason?
uint lastVoteTime = 0;
bool canVote = true;

// Are we actually in a server. 
bool inServerMap = false;


//UI
void RenderMenu()
{
    if (UI::MenuItem("Quick Vote Commands", "", showWindow)) {
        showWindow = !showWindow;
    }
}

void Render()
{
    if (!showWindow || !inServerMap) {
        return;
    }

    UI::SetNextWindowSize(windowWidth, windowHeight, UI::Cond::Appearing);
    UI::SetNextWindowPos(windowX, windowY, UI::Cond::Appearing);

    if (UI::Begin("Quick Vote Commands", showWindow)) {
        SaveWindowBounds();

        float buttonSize = GetButtonSize();
        vec2 buttonSquare = vec2(buttonSize, buttonSize);
        if (UI::Button(Icons::StepForward + "##VoteSkip", buttonSquare)) {
            RequestMapVote(VoteRequest::NextMap);
        }
        AddTooltip("Skip Map");

        UI::SameLine(0, buttonSpacing);
        if (UI::Button(Icons::Refresh + "##VoteRestart", buttonSquare)) {
            RequestMapVote(VoteRequest::RestartMap);
        }
        AddTooltip("Restart Map");

        UI::SameLine(0, buttonSpacing);
        if (UI::Button(Icons::Check + "##VoteYes", buttonSquare)) {
            CastVote(true);
        }
        AddTooltip("Vote Yes");

        UI::SameLine(0, buttonSpacing);
        if (UI::Button(Icons::Times + "##VoteNo", buttonSquare)) {
            CastVote(false);
        }
        AddTooltip("Vote No");
    }
    UI::End();
}

void SaveWindowBounds()
{
    vec2 windowPos = UI::GetWindowPos();
    vec2 windowSize = UI::GetWindowSize();

    windowX = windowPos.x;
    windowY = windowPos.y;
    windowWidth = windowSize.x;
    windowHeight = windowSize.y;
}

void AddTooltip(const string &in text)
{
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text(text);
        UI::EndTooltip();
    }
}

float GetButtonSize()
{
    float contentWidth = UI::GetContentRegionAvail().x;
    float totalSpacing = buttonSpacing * (buttonCount - 1.0f);
    return Math::Max(minbuttonSize, Math::Floor((contentWidth - totalSpacing) / buttonCount));
}


// Voting
enum VoteRequest
{
    NextMap,
    RestartMap
}

void RequestMapVote(VoteRequest request)
{
    auto playgroundClientAPI = GetPlaygroundClientScriptAPI();
    if (playgroundClientAPI is null || !canVote) {
        return;
    }
    if (request == VoteRequest::NextMap) {
        playgroundClientAPI.RequestNextMap();
    } else {
        playgroundClientAPI.RequestRestartMap();
    }
    setLastVoteTime();
}

void CastVote(bool yesNo)
{
    auto playgroundClientAPI = GetPlaygroundClientScriptAPI();
    if (playgroundClientAPI is null || !playgroundClientAPI.Vote_CanVote || !canVote) {
        return;
    }
    playgroundClientAPI.Vote_Cast(yesNo);
    setLastVoteTime();
}

void setLastVoteTime() {
    lastVoteTime = Time::Now;
}

bool sufficientTimeSinceLastVote() {
    return (Time::Now - lastVoteTime) > 2000; // 2 second cooldown
}

// Checking game state every frame to see if we're in a server lobby
void Update(float dt)
{
    auto app = GetApp();
        if (app.Network is null || app.CurrentPlayground is null || app.RootMap is null) {
            // Main menu or loading screen
            inServerMap = false;
        } else {
            auto serverInfo = app.Network is null ? null : cast<CGameCtnNetServerInfo>(app.Network.ServerInfo);
            if(serverInfo !is null && serverInfo.ServerLogin != "") {
                // In server
                inServerMap = true;
            } else {
                // In local track
                inServerMap = false;
            }
        }
        canVote = sufficientTimeSinceLastVote();
}

// Util
CGamePlaygroundClientScriptAPI@ GetPlaygroundClientScriptAPI()
{
    auto app = GetApp();
    auto network = cast<CTrackManiaNetwork>(app.Network);
    if (network is null) {
        return null;
    }
    return network.PlaygroundClientScriptAPI;
}
