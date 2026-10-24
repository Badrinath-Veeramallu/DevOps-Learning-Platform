/**
 * 21st.dev inspired Segmented Tabs
 */
export const Tabs = ({ tabs = [], activeTab, onChange, className = "" }) => {
  return (
    <div className={`devops-tabs-container ${className}`} role="tablist">
      {tabs.map((tab) => {
        const isActive = activeTab === tab.id;
        return (
          <button
            key={tab.id}
            role="tab"
            aria-selected={isActive}
            onClick={() => onChange(tab.id)}
            className={`devops-tab-item ${isActive ? "devops-tab-active" : ""}`}
          >
            {tab.icon && <span className="tab-icon">{tab.icon}</span>}
            <span>{tab.label}</span>
            {tab.badge && (
              <span className="tab-badge">{tab.badge}</span>
            )}
          </button>
        );
      })}
    </div>
  );
};

export default Tabs;
