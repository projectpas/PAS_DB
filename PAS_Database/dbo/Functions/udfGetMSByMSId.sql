
CREATE FUNCTION [dbo].[udfGetMSByMSId] (
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
		AND  IsActive = 1 and IsDeleted = 0