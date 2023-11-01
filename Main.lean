import Lean

open Lean

namespace GPT

inductive Role where | user | assistant | system
deriving ToJson, FromJson

structure Message where
  role : Role
  content : String
deriving ToJson, FromJson

def getJsonResponse (req : Json) : IO Json := do
  let some apiKey ← IO.getEnv "OPENAI_API_KEY" |
    throw <| .userError "Failed to fetch OpenAI API key"
  let child ← IO.Process.spawn {
    cmd := "curl"
    args := #[
      "https://api.openai.com/v1/chat/completions",
      "-H", "Content-Type: application/json",
      "-H", "Authorization: Bearer " ++ apiKey,
      "--data-binary", "@-"]
    stdin := .piped
    stderr := .piped
    stdout := .piped
  }
  let (stdin,child) ← child.takeStdin
  stdin.putStr <| toString req
  stdin.flush
  let stdout ← IO.asTask child.stdout.readToEnd .dedicated
  let err ← child.stderr.readToEnd
  let exitCode ← child.wait
  if exitCode != 0 then throw <| .userError err
  let out ← IO.ofExcept stdout.get
  match Json.parse out with
  | .ok json => return json
  | .error err => throw <| .userError s!"{err}\n{req}"

def getResponses (msgs : Array Message) (n : Nat := 1) : IO (Array GPT.Message) := do
  let req : Json :=
    Json.mkObj [
      ("model", "gpt-4"),
      ("messages", toJson <| msgs),
      ("n", n)
    ]
  let jsonResponse ← getJsonResponse req
  let .ok choices := jsonResponse.getObjValAs? (Array Json) "choices" |
    throw <| .userError s!"Failed to parse choices as array:
{jsonResponse}"
  let .ok choices := choices.mapM fun j => j.getObjValAs? GPT.Message "message" |
    throw <| .userError s!"Failed to parse messages:
{choices}"
  return choices

def getResponse (msgs : Array Message) : IO GPT.Message := do
  let msgs ← getResponses msgs
  let some msg := msgs[0]? |
    throw <| .userError s!"No messages were returned."
  return msg

elab "#find_with_gpt" s:str : command => do
  unless '.' ∈ s.getString.toList do
    return
  let query := s.getString
  let sysPrompt : GPT.Message := {
    role := .system
    content := "You are an expert mathematician and user of the Lean4 interactive proof assistant.
Your task is to translate the user's entry into a Lean4 type expression.

Examples:

Input:
If $n$ is a natural number, then $n % 2 = 0$ or $n % 2 = 1$.
Output:
∀ (n : ℕ), n % 2 = 0 ∨ n % 2 = 1

Input:
If $G$ is a commutative group and $a,b ∈ G$, then $a * b = b * a$.
Output:
∀ (G : Type*) [CommGroup G] (a b : G), a * b = b * a
"
  }
  let query : GPT.Message := {
    role := .user
    content := query
  }
  let res ← GPT.getResponse #[sysPrompt, query]
  let query : Json := .mkObj [
    ("query", res.content),
    ("results", 10)
  ]
  let res ← IO.Process.output {
    cmd := "curl"
    args := #[
      "localhost:8000",
      "-X", "GET",
      "-H", "Content-Type: application/json",
      "-d", query.compress
    ]
  }
  let .ok res := Json.parse res.stdout
    | throwError "Error"
  let .ok (res : Array Json) := fromJson? res
    | throwError "Error"
  for item in res do
    let .ok module := item.getObjValAs? String "module"
      | throwError "Error"
    let .ok name := item.getObjValAs? String "name"
      | throwError "Error"
    let .ok type := item.getObjValAs? String "type"
      | throwError "type"
    IO.println module
    IO.println name
    IO.println type
    IO.println "---"















































































--
