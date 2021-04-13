page 30057 "APIV2 - Aut. Conf. Pack. File"
{
    DelayedInsert = true;
    Extensible = false;
    PageType = ListPart;
    SourceTable = "Tenant Config. Package File";
    ODataKeyFields = Code;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(code; Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                    Editable = false;
                }
                field(content; Content)
                {
                    ApplicationArea = All;
                    Caption = 'Content';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        CodeFilter: Text;
    begin
        if not FilesLoaded then begin
            CodeFilter := GetFilter(Code);
            if CodeFilter = '' then
                Error(CodeNotSpecifiedForLinesErr);
            if not FindFirst() then
                exit(false);
            FilesLoaded := true;
        end;

        exit(true);
    end;

    trigger OnOpenPage()
    begin
        BindSubscription(AutomationAPIManagement);
    end;

    var
        AutomationAPIManagement: Codeunit "Automation - API Management";
        FilesLoaded: Boolean;
        CodeNotSpecifiedForLinesErr: Label 'You must specify a Configuration Package Code before uploading a Configuration Package File.', Locked = true;
}