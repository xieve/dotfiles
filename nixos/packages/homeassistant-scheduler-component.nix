{
  buildHomeAssistantComponent,
  inputs,
}:
buildHomeAssistantComponent {
  src = inputs.home-assistant-component-scheduler;
  domain = "scheduler";
  version = "3.3.8";
  owner = "nielsfaber";
}
