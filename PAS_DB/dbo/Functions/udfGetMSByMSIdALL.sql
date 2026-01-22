
CREATE FUNCTION [dbo].[udfGetMSByMSIdALL] (
    @msID INT
)
RETURNS TABLE
AS
RETURN
    SELECT 
		MS.ManagementStructureId
        FROM
		dbo.ManagementStructure MS WITH (NOLOCK)
		WHERE
        ParentId = @msID